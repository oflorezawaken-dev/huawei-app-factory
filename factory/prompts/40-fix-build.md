# Step: fix a failing Factory Build

Read `factory/prompts/00-factory-rules.md` first. Input: the failing run URL or ID and
the app slug.

## Method

1. `gh run view <run_id> --log-failed` and read the FIRST real error, not the last line.
2. Reproduce locally in `apps/<slug>` with the same Gradle task.
3. Make the smallest change that fixes the root cause. Do not:
   - delete or `@Ignore` tests to pass,
   - add `-x test`, `ignoreFailures`, or `lintOptions.abortOnError=false`,
   - bump dependency versions blindly,
   - change `applicationId`, `versionCode`, `versionName`, `minSdk`, or signing config.
4. Re-run the task locally, then `python factory/tools/check_app.py <slug>`.
5. Commit as `fix(<slug>): <what and why>` with the error message quoted in the body.
   Push to the same branch. One fix attempt per run; if the second run still fails,
   stop and report what you found instead of trying a third blind change.
