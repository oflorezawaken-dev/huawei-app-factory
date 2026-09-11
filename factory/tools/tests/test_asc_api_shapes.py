#!/usr/bin/env python3
"""
Every App Store Connect API call the factory makes, checked against Apple's
own OpenAPI specification -- offline, before anything runs.

  python factory/tools/tests/test_asc_api_shapes.py

Why this exists. Across the first two apps, eight separate failures were the
same failure: a path, verb, field or relationship name that I had guessed and
the mock had accepted. `appStoreVersionState` (400), `APP_IPHONE_69`,
`DELETE /v1/reviewSubmissions/{id}` (403), `inAppPurchaseV2` (409),
`appStoreVersions/{id}/ageRatingDeclaration` (404), `apps/{id}/appDataUsages`
(404), `PATCH canceled` on a submission that cannot be cancelled (409). Each
one cost a real submission attempt to discover, and several left state behind
that App Store Connect does not let you undo.

Apple publishes the specification (developer.apple.com/sample-code/app-store-connect/
app-store-connect-openapi-specification.zip). A slimmed copy lives in
factory/tools/spec/. This test reads every `api_call(...)` and `api_get(...)`
out of the tools' source and asserts the path and verb exist, and that the
relationship names used on create requests exist on the schema. Four of the
eight would have failed here.

What it cannot see: behaviour. `filter[screenshotDisplayType]` is in the spec
and Apple ignores it at runtime. Shape is necessary, not sufficient; the mock
still has to be as unhelpful as Apple is.
"""

from __future__ import annotations

import gzip
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
SPEC = os.path.join(TOOLS, "spec", "asc-openapi.slim.json.gz")
SOURCES = ["asc_metadata.py", "asc_publish.py", "asc_watch.py", "asc_client.py", "asc_setup.py"]

# Paths built from a variable resource name cannot be checked statically.
# They are listed so a new one is a deliberate decision, not an accident.
DYNAMIC_OK = {
    "/v1/{resource}",
    "/v1/{resource}/{id}",
    "/v1/{parent_field}/{id}/{resource}",
}


def load_spec() -> dict:
    with gzip.open(SPEC, "rt", encoding="utf-8") as fh:
        return json.load(fh)


def normalise(path: str) -> str:
    """f-string holes become {id}, except named resource holes, which stay named."""
    path = path.split("?", 1)[0]
    def hole(m):
        name = m.group(1)
        return "{" + name + "}" if name in ("resource", "parent_field") else "{id}"
    return re.sub(r"\{([^}]*)\}", hole, path)


def calls_in(source: str) -> list[tuple[str, str, str]]:
    """(method, raw_path, filters) for every api_call / api_get in the file."""
    out = []
    for m in re.finditer(r'api_call\(\s*"(GET|POST|PATCH|DELETE)",\s*f?"([^"]+)"', source):
        out.append((m.group(1), m.group(2), m.group(2)))
    for m in re.finditer(r'api_get\(\s*f?"([^"]+)"', source):
        out.append(("GET", m.group(1), m.group(1)))
    return out


def relationships_used(source: str) -> list[str]:
    """Relationship names under a reviewSubmissionItems create body."""
    block = re.search(r'"type": "reviewSubmissionItems".*?\}\}\}', source, re.S)
    names = []
    for chunk in re.finditer(r'"type": "reviewSubmissionItems",\s*"relationships": \{(.*?)\}\}\}\}', source, re.S):
        names += re.findall(r'"(\w+)": \{\s*"data"', chunk.group(1))
        names += re.findall(r'(\w+): \{\s*"data"', chunk.group(1))  # a variable key
    return sorted(set(n for n in names if n != "reviewSubmission"))


def create_relationships(spec: dict, schema: str) -> set[str]:
    S = spec["components"]["schemas"]
    def deref(node):
        while isinstance(node, dict) and "$ref" in node:
            node = S[node["$ref"].rsplit("/", 1)[-1]]
        return node
    data = deref(deref(S[schema])["properties"]["data"])
    rel = deref(data["properties"].get("relationships", {}))
    return set(rel.get("properties", {}).keys())


def main() -> int:
    spec = load_spec()
    paths = spec["paths"]
    failures: list[str] = []
    checked = 0

    def check(label: str, ok: bool, detail: str = "") -> None:
        print(f"  {'ok  ' if ok else 'FAIL'}  {label}" + (f"  -- {detail}" if detail and not ok else ""))
        if not ok:
            failures.append(label)

    print(f"Apple App Store Connect OpenAPI {spec['info'].get('version')}, {len(paths)} paths\n")

    for name in SOURCES:
        src_path = os.path.join(TOOLS, name)
        if not os.path.isfile(src_path):
            continue
        source = open(src_path, encoding="utf-8").read()
        print(f"{name}:")
        for method, raw, _ in calls_in(source):
            path = normalise(raw)
            if path in DYNAMIC_OK:
                print(f"  skip  {method:6} {path}  (resource chosen at runtime)")
                continue
            checked += 1
            ops = paths.get(path)
            if ops is None:
                check(f"{method} {path}", False, "no such path in Apple's spec")
                continue
            check(f"{method} {path}", method.lower() in ops,
                  f"Apple allows only {sorted(k.upper() for k in ops)}")
            # Query filters must be parameters Apple accepts on that operation.
            if "?" in raw and method.lower() in ops:
                allowed = set(ops[method.lower()].get("parameters") or [])
                for param in re.findall(r"[?&]([^=&]+)=", raw):
                    if param.startswith("filter[") or param in ("limit", "include"):
                        check(f"    {param} on {path}", param in allowed,
                              f"accepted: {sorted(p for p in allowed if p.startswith('filter'))}")

        # The one create body whose relationship name has already bitten twice.
        used = relationships_used(source)
        if used:
            allowed = create_relationships(spec, "ReviewSubmissionItemCreateRequest")
            for rel in used:
                # A variable as the key defeats this check entirely -- that is
                # how a "try both candidate names" loop passed here while both
                # candidates were wrong. Relationship names must be literals.
                check(f"reviewSubmissionItems relationship '{rel}'", rel in allowed,
                      f"not a relationship Apple accepts here. Apple accepts: {sorted(allowed)}")
        print()

    print(f"{checked} call(s) checked against the spec")
    if failures:
        print(f"\n{len(failures)} shape(s) Apple would refuse:")
        for f in failures:
            print(f"  - {f}")
        print("\nFix the call, do not loosen this test: each of these costs a real submission "
              "attempt to discover otherwise, and some leave state App Store Connect will not undo.")
        return 1
    print("\nall API shapes match Apple's specification")
    return 0


if __name__ == "__main__":
    sys.exit(main())
