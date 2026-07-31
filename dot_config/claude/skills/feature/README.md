# /feature

Full TDD feature development pipeline for Claude Code. Takes a feature description and runs it through planning, test-driven implementation,
code simplification, verification, two review passes, and PR creation.

## Usage

/feature

**Examples:**
/feature add password reset flow with 1-hour expiry tokens
/feature PROJ-412: export user data as CSV from settings page

## What it does

| Step | What happens |
|------|-------------|
| 0 | Checks deps, installs anything missing, creates the feature branch |
| 1 | Optional: assigns the referenced ticket and moves it to in progress |
| 2 | Establishes the spec (from a ticket, TRD, or plan file), validates its assumptions against the code, decomposes it into tasks, gets your approval, then pauses to compact |
| 3 | Writes concrete, falsifiable prove statements |
| 4 | Writes failing tests first (TDD) |
| 5 | Implements task-by-task via subagents, then pauses to compact |
| 6 | Runs code-simplifier, which tests the files it changed |
| 7 | Runs prove_it verification against each statement |
| 8 | Two review passes: a cold reviewer with no context, then a coherence pass looking only for cross-task problems |
| 9 | Cleans up, deletes planning artifacts, lints, creates a draft PR via `gh` |
| 10 | Watches all three review-comment surfaces, addresses them, pushes, repeats until approved |

## How much runs locally

Tests and lint run once per change, by whoever made the change, scoped to the files it touched. Nothing re-runs them afterwards: the
reviewers in Steps 5 and 8 are read-only and read the diff instead. A failing test or a lint violation is caught by CI on push regardless,
so the pipeline spends its local time on the review passes, which find what CI cannot.

Step 7 runs whatever commands `.claude/prove_statements.md` names, verbatim. The pipeline writes those statements scoped to the feature and
announces the commands before Step 4 runs them, so you can see what it picked. Edit that file to change what runs; nothing else in the
pipeline broadens it.

## Compaction stops

The pipeline stops twice, after Step 2 and after Step 5, and asks you to run `/compact`. Those are also the two cheap moments to change the
orchestrator model, since prompt caches are per-model and there is little context left to re-warm right after a compact. Each handoff
therefore offers a `/model` switch. Both are optional and nothing downstream depends on them.

## Dependencies

- [`prove_it`](https://github.com/searlsco/prove_it): `brew install searlsco/tap/prove_it && prove_it install`
- `code-simplifier` plugin: `/plugin install code-simplifier@claude-plugin-directory`
- `gh` CLI: `brew install gh`
- The `feature-*` role definitions in `~/.config/claude/agents/`, which set each subagent's model, reasoning effort, and tool scope.
  Without them the `subagent_type` dispatches from Step 2 onward will not resolve.

## Optional

- **Ticket tracking**: Step 1 assigns the ticket and moves it to in progress through whichever issue-tracker MCP is configured, when the
  feature description references one.
