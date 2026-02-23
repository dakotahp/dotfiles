# /feature

Full TDD feature development pipeline for Claude Code. Takes a feature description and runs it through planning, test-driven implementation,
code simplification, verification, review, and PR creation autonomously.

## Usage

/feature

**Examples:**
/feature add password reset flow with 1-hour expiry tokens
/feature PROJ-412: export user data as CSV from settings page

## What it does

| Step | What happens |
|------|-------------|
| 0 | Checks deps, installs anything missing |
| 1 | Plans the feature (Convext if configured, otherwise Claude plan mode) |
| 2 | Writes concrete, falsifiable prove statements |
| 3 | Writes failing tests first (TDD) |
| 4 | Implements — spawns parallel sub-agents when beneficial |
| 5 | Runs code-simplifier, re-runs tests |
| 6 | Runs prove_it verification against each statement |
| 7 | Spawns code-reviewer agent, addresses all issues |
| 8 | Removes comment noise, lints, creates PR via `gh` |
| 9 | Watches for review comments, addresses them, pushes |
| 10 | Pings Slack (or prints summary) when ready for human review |

## Dependencies

- [`prove_it`](https://github.com/searlsco/prove_it) — `brew install searlsco/tap/prove_it && prove_it install`
- `code-simplifier` plugin — `/plugin install code-simplifier@claude-plugin-directory`
- `gh` CLI — `brew install gh`

## Optional

- **Convext** — if configured (`CONVEXT_PROJECT_ID` env var, `.convext/config.json`, or `convext` key in `.claude/settings.json`), used for
task tracking in step 1 instead of plan mode
- **Slack** — set `SLACK_WEBHOOK` env var for step 10 notifications
