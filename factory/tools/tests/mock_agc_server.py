#!/usr/bin/env python3
"""
Minimal mock of the AppGallery Connect Publishing API for local testing of
agc_publish.py. Not used in CI against Huawei. Run:

  python factory/tools/tests/mock_agc_server.py 8765 &
  AGC_API_BASE=http://127.0.0.1:8765/api AGC_CLIENT_ID=x AGC_CLIENT_SECRET=y \
    python factory/tools/agc_publish.py --package-name com.example --file some.apk --submit --release-notes "Mock release notes"
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

CALLS = []


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, payload=None, raw=b""):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode() if payload is not None else raw)

    def _body(self):
        n = int(self.headers.get("Content-Length") or 0)
        return self.rfile.read(n) if n else b""

    def log_message(self, *a):  # quiet
        pass

    def do_POST(self):
        u = urlparse(self.path)
        body = self._body()
        CALLS.append(("POST", u.path))
        if u.path == "/api/oauth2/v1/token":
            d = json.loads(body)
            assert d["grant_type"] == "client_credentials" and d["client_id"] and d["client_secret"]
            return self._send(200, {"access_token": "mock-token", "expires_in": 172800})
        if u.path == "/api/publish/v2/app-submit":
            q = parse_qs(u.query)
            assert self.headers["Authorization"] == "Bearer mock-token" and self.headers["client_id"]
            assert q["appId"] == ["123456"] and 10 <= len(q["remark"][0]) <= 300
            return self._send(200, {"ret": {"code": 0, "msg": "success"}})
        return self._send(404, {"ret": {"code": 404, "msg": "not found"}})

    def do_GET(self):
        u = urlparse(self.path)
        q = parse_qs(u.query)
        CALLS.append(("GET", u.path))
        assert self.headers["Authorization"] == "Bearer mock-token"
        if u.path == "/api/publish/v2/appid-list":
            assert q["packageName"]
            return self._send(200, {"ret": {"code": 0}, "appids": [{"key": "", "value": "123456"}]})
        if u.path == "/api/publish/v2/upload-url/for-obs":
            assert q["appId"] == ["123456"] and q["suffix"][0] in ("apk", "aab") and int(q["contentLength"][0]) > 0
            return self._send(200, {
                "ret": {"code": 0},
                "urlInfo": {
                    "url": f"http://{self.headers['Host']}/obs/bucket/object-1",
                    "method": "PUT",
                    "objectId": "object-1",
                    "headers": {"Content-Type": "application/octet-stream", "x-amz-date": "20260906T000000Z"},
                },
            })
        if u.path == "/api/publish/v2/aab/complile/status":
            return self._send(200, {"ret": {"code": 0}, "pkgStateList": [{"pkgId": p, "aabCompileStatus": 2} for p in q["pkgIds"][0].split(",")]})
        return self._send(404, {"ret": {"code": 404, "msg": "not found"}})

    def do_PUT(self):
        u = urlparse(self.path)
        body = self._body()
        CALLS.append(("PUT", u.path))
        if u.path.startswith("/obs/"):
            assert len(body) > 0 and self.headers["x-amz-date"]
            return self._send(200, raw=b"")
        if u.path == "/api/publish/v2/app-file-info":
            d = json.loads(body)
            assert d["fileType"] == 5 and d["files"][0]["fileDestUrl"] == "object-1" and d["files"][0]["fileName"].startswith("release.")
            return self._send(200, {"ret": {"code": 0}, "pkgVersion": ["987"]})
        return self._send(404, {"ret": {"code": 404, "msg": "not found"}})


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
