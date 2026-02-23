---
name: pr-description
description: Generates a pull request title and description for the current branch. Explains the why, the technical approach, and includes ASCII or Mermaid diagrams where they add clarity. Pass optional context such as a ticket number or additional intent.
allowed-tools: Bash, Read, Glob, Grep, Task
---

Generate a pull request title and full description for the current branch. If $ARGUMENTS is provided, treat it as additional context (ticket number, intent, audience, or anything else relevant) and factor it into the output.

The description must be written so that a reviewer with little prior context of the task or codebase can fully understand what changed, why, and how.

---

## Step 1 — Understand the branch changes

Determine the base branch:
```
git rev-parse --abbrev-ref HEAD
git merge-base HEAD $(git symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||') 2>/dev/null || git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Then read:
- All commits on this branch since diverging from the base: `git log <base>..HEAD --oneline`
- The full diff against the base: `git diff <base>..HEAD`

---

## Step 2 — Read the PR template if one exists

Check for a pull request template:
- `.github/pull_request_template.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/PULL_REQUEST_TEMPLATE/*.md`

If a template exists, use it as the structure for the description, filling in each section. If no template exists, use the output format defined in Step 6.

---

## Step 3 — Check commit style and any contribution guidelines

Run `git log --oneline -20` to understand the repo's commit and PR title conventions.

Check for guidelines in:
- `CONTRIBUTING.md`
- `.github/CONTRIBUTING.md`
- `CLAUDE.md`

---

## Step 4 — Analyze the technical approach in context

Spawn an Explore sub-agent to read the files touched by this branch's diff in the context of the surrounding codebase. The goal is to understand not just what changed, but how it fits into the system.

The sub-agent should identify:
- What problem the change is solving
- What the implementation approach is and why it was likely chosen
- Which parts of the system are affected (callers, dependents, data flow)
- Any notable trade-offs in the approach
- Whether the change is isolated or touches shared/core infrastructure

---

## Step 5 — Determine where diagrams add value

Consider diagrams for any of the following where they are present in this change:
- A new or significantly changed code path or request lifecycle
- Data flow between components, services, or layers
- State transitions or lifecycle events
- Database schema relationships
- Before/after architectural comparisons

Prefer **Mermaid** diagrams (flowchart, sequenceDiagram, erDiagram, stateDiagram) when the relationship has clear directionality or sequence. Use **ASCII** when the relationship is spatial or structural (e.g. a component tree or file layout).

Only include diagrams where they genuinely aid understanding. Do not add them for the sake of it.

---

## Step 6 — Output the PR description

If no template was found in Step 2, use this structure:

```
<title>

## Why

<Why this change was needed. What problem it solves or what goal it serves.
Written for someone unfamiliar with the task — no assumed context.>

## What changed

<A clear summary of what was done. High level first, then specifics.
Use bullet points for multiple distinct changes.>

## Technical approach

<Explain the implementation decisions. Why this approach over alternatives.
What the key moving parts are and how they interact.
Include diagrams here where applicable.>

## How to test it

<Steps a reviewer can follow to verify the change works as intended.>

## Notes

<Anything else worth flagging: follow-up work, known limitations,
areas of uncertainty, or things to pay particular attention to in review.
Omit this section if there is nothing to add.>
```

Rules for the title:
- 72 characters or fewer
- Imperative mood
- No trailing period
- Match the casing and prefix style of the repo's existing commits and PRs

Output only the PR description in a single code block, ready to paste. No surrounding commentary.
