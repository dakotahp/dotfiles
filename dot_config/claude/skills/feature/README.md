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
| 2 | Brainstorms and writes the plan, stress-tests it with two independent reviewers, gets your approval, then pauses to compact |
| 3 | Writes concrete, falsifiable prove statements |
| 4 | Writes failing tests first (TDD) |
| 5 | Implements task-by-task via subagents, then pauses to compact |
| 6 | Runs code-simplifier, re-runs tests |
| 7 | Runs prove_it verification against each statement |
| 8 | Two review passes: a cold reviewer with no context, then a warm one with full context |
| 9 | Cleans up, deletes planning artifacts, lints, creates a draft PR via `gh` |
| 10 | Watches all three review-comment surfaces, addresses them, pushes, repeats until approved |

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
