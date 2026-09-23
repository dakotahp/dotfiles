# /feature

TDD pipeline for Claude Code. Takes a specified ticket through spec validation, failing tests, implementation, two review passes, and a draft PR.

## Usage

```
/feature APP-412
/feature docs/plans/2026-09-18-csv-export-trd.md ticket 3
/feature APP-412 --lane      # started by /run-lanes, skips the plan approval wait
/feature APP-413 --stack-on feature/app-412-export-endpoint   # builds on an open PR
```

## Stacked branches

With `--stack-on <branch>`, the feature branch starts from that branch, not from trunk. git-spice records the parent link. The draft PR targets the parent, and the diff shows only this ticket's commits. While it waits on CI, the session restacks its own branch when the parent moves or merges. It never restacks branches that other sessions own, and it never merges.

## What it does

| Step | What happens |
|------|-------------|
| 0 | Checks dependencies, creates a worktree and feature branch, links the prove_it files |
| 1 | Optional: assigns the ticket and moves it to In Progress |
| 2 | Establishes the spec, validates its assumptions against the code, splits it into tasks, gets your approval |
| 3 | Writes falsifiable prove statements |
| 4 | Writes failing tests |
| 5 | Implements task by task through subagents, each task reviewed as it lands |
| 6 | Verifies each prove statement with prove_it |
| 7 | A cold review with no context, then a cross-task coherence review |
| 8 | Removes debug code and planning files, lints the branch |
| 9 | Creates the draft PR |
| 10 | Watches CI, mergeability, and the review bot, fixes what it finds, then hands the PR to you |

## Where it stops

Interactive runs stop once, at plan approval in Step 2. Lane runs do not stop there. Both stop on a false spec assumption, a rebase conflict that needs your intent, or placeholder prove_it scripts.

The deliverable is a draft PR with green automated signals. Requesting reviews, marking it ready, and merging are yours. It does not wait for human reviewers.

## Model and effort

Run the main session at `sonnet` / `high`, the default the `claude` shell wrapper sets on every launch. `/run-lanes` passes both flags explicitly. Each subagent's model and effort come from its own definition file.

## prove_it files

Step 0 links `script/test`, `script/test_fast`, `.claude/prove_it/config.json`, and `.claude/rules/*.md` from the main checkout into each worktree, and adds them to `.git/info/exclude`. Fix those files once in the main checkout, and every worktree picks up the fix. The global git hooks in `~/.config/git/hooks` clear prove_it's change-tracking refs after a pull, branch switch, or rebase, so they do not go stale.

## Dependencies

- [`prove_it`](https://github.com/searlsco/prove_it): `brew install searlsco/tap/prove_it && prove_it install`
- `gh`: `brew install gh`
- `git-spice`, for stacked branches: installed by `packages.toml`. Run `git-spice auth login` once per machine and pick the GitHub CLI method.
- The `feature-*`, `plan-falsifier`, and `plan-rederiver` definitions in `~/.config/claude/agents/`
