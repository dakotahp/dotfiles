# /feature

Full TDD feature development pipeline for Claude Code. Takes a feature description and runs it through planning, test-driven implementation,
verification, two review passes, and PR creation.

## Usage

/feature

**Examples:**
/feature add password reset flow with 1-hour expiry tokens
/feature PROJ-412: export user data as CSV from settings page

## What it does

| Step | What happens |
|------|-------------|
| 0 | Confirms the model and effort level, checks deps, installs anything missing, creates the feature branch |
| 1 | Optional: assigns the referenced ticket and moves it to in progress |
| 2 | Establishes the spec (from a ticket, TRD, or plan file), validates its assumptions against the code, decomposes it into tasks, gets your approval, then pauses to compact |
| 3 | Writes concrete, falsifiable prove statements |
| 4 | Writes failing tests first (TDD) |
| 5 | Implements task-by-task via subagents, each task reviewed for correctness and readability as it lands, then pauses to compact |
| 6 | Runs prove_it verification against each statement |
| 7 | Two review passes: a cold reviewer with no context, then a coherence pass looking only for cross-task problems |
| 8 | Cleans up debug code, deletes planning artifacts, lints the branch |
| 9 | Creates the draft PR via `gh` and opens it in your browser |
| 10 | Watches CI, mergeability, and the automated reviewer, fixes what it finds (including rebasing a conflicted branch), pushes, repeats until all three are clean, then hands the PR to you |

## Where it stops

The pipeline's whole deliverable is a draft PR with green automated signals. Requesting reviews, marking the PR ready, and merging are yours, and the skill will not do them, ask about them, or offer.

It also will not wait for a human reviewer. Step 10 polls the signals that land in minutes (CI, mergeability, the review bot) and then ends. A colleague's comments usually arrive long after the session is over, so bringing those back is a fresh `/feature` or `/code-review` run when you want it.

## How much runs locally

Tests and lint run once per change, by whoever made the change, scoped to the files it touched. Nothing re-runs them afterwards: the
reviewers in Steps 5 and 7 are read-only and read the diff instead. A failing test or a lint violation is caught by CI on push regardless,
so the pipeline spends its local time on the review passes, which find what CI cannot.

Step 6 runs whatever commands `.claude/prove_statements.md` names, verbatim. The pipeline writes those statements scoped to the feature and
announces the commands at the end of Step 3, so you can see what it picked before anything runs them. Edit that file to change what runs;
nothing else in the pipeline broadens it.

## Model and effort

The pipeline expects `sonnet` at `high` effort, and Step 0 stops to confirm it before doing anything else. Claude Code carries the last
session's model and effort into the next one, so the starting tier is usually an artifact of whatever you did previously rather than a
choice. The orchestrator mostly dispatches roles and reads back summaries, and each subagent's model and effort come from its own definition
file, so sonnet/high is enough for the main session. Escalate to opus only in reaction to something: a false assumption from the spec
falsifier, or Critical findings at 7a.

Step 0 can report the model it is running but cannot see the effort level at all, so it hands that check to you.

## Compaction stops

The pipeline stops twice, after Step 2 and after Step 5, and asks you to run `/compact`. The Step 2 stop also asks you to `/rename` the
session so it stays findable in the session list.

## Dependencies

- [`prove_it`](https://github.com/searlsco/prove_it): `brew install searlsco/tap/prove_it && prove_it install`
- `gh` CLI: `brew install gh`
- The `feature-*` role definitions in `~/.config/claude/agents/`, which set each subagent's model, reasoning effort, and tool scope.
  Without them the `subagent_type` dispatches from Step 2 onward will not resolve.

## Optional

- **Ticket tracking**: Step 1 assigns the ticket and moves it to in progress through whichever issue-tracker MCP is configured, when the
  feature description references one.
