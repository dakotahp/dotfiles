# User-Level Claude Instructions

## Pre-Commit Requirements

Before every `git commit`, without exception:

1. Run the full test suite and confirm 0 failures
2. Run the linter on all changed files and fix any violations
3. In frontend repos (any repo with a `package.json` build script), run the build and confirm it succeeds

Do not commit until all three pass cleanly. If a step fails, fix the issue and re-run that step before proceeding. Do not skip or work around these checks.

**Exception:** If a check fails due to pre-existing failures on the main branch (not caused by your changes), stop and report what is failing and why you believe it's pre-existing. Do not proceed until the user explicitly says "skip pre-commit checks" or "you can commit anyway."
