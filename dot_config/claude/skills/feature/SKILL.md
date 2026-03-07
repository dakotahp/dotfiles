---
name: feature
description: Use when implementing a new feature from scratch, before writing any implementation code.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task
---

Implement the feature described in $ARGUMENTS by following every step below in order. Do not skip steps. Do not move to the next step until the current one is fully complete.

**This skill is the master pipeline.** All other skills invoked during this pipeline (brainstorming, writing-plans, subagent-driven-development, requesting-code-review, etc.) are sub-routines. After any sub-skill completes, immediately return to this pipeline and continue from the next numbered step. This pipeline is complete only when Step 11 has been executed.

---

## Step 0 — Check and install dependencies

Check that the following tools are available on PATH:

- `gh` (GitHub CLI)
- `prove_it`
- Any project-specific tooling referenced in the README, `package.json` scripts, `Makefile`, or equivalent

For each missing tool, install it using the appropriate package manager:

- `gh`: `brew install gh`
- `prove_it`: `brew install searlsco/tap/prove_it && prove_it install`
- Project tools: use npm, brew, pip, cargo, etc. as appropriate

If `prove_it` has not been initialised in this project yet, run `prove_it init`.

### Feature branch

**Before any planning or code**, confirm you are not on `main` or `master`:

```bash
git branch --show-current
```

If you are on a protected branch, create a feature branch now and check it out:

```bash
git checkout -b feature/<short-kebab-case-description>
```

Derive the name from $ARGUMENTS (e.g. `feature/stripe-webhook`, `feature/phase4-security`). This branch is where every commit in this pipeline lands — including commits from subagents. Never commit to `main` or `master`. Record the branch name; you will pass it explicitly to every subagent you dispatch in Step 5.

---

## Step 1 (optional) - Start and assign ticket

If a ticket is being referenced, use the appropriate MCP to assign the ticket to me and move it into in progress.

---

## Step 2 — Plan the feature

Invoke `superpowers:brainstorming` as a sub-step to explore requirements and design space. After it completes, invoke `superpowers:writing-plans` to produce the implementation plan. The plan must cover:

- What will be created or changed and why
- Files to be added or modified
- Key architectural decisions and trade-offs
- Anything that needs clarification before work begins

**IMPORTANT:** Skip the writing-plans "Execution Handoff" section entirely — do NOT ask the user which execution approach to use. This pipeline controls execution flow; the writing-plans skill is a sub-routine here. Execution will use subagent-driven-development in Step 5.

Wait for explicit user approval of the plan before continuing. Approval means the user says something like "approved", "looks good", "proceed", or an unambiguous equivalent. **Feedback without approval is NOT approval** — incorporate the feedback, update the plan, and re-present it. Do not interpret silence or partial responses as approval. **After approval, return to this pipeline. Continue to Step 3.**

---

## Step 3 — Write prove statements

Create or update the file `.claude/prove_statements.md` with concrete, falsifiable statements that describe what the implemented feature will do. Each statement must be:

- Specific and measurable — not "it works", but "running X produces Y"
- Independently verifiable using real commands or observable outputs
- Tied to a behaviour introduced by this feature

**Good example:** "`npm test` exits 0 and output contains 'auth › login: 3 passed, 0 failed'."
**Bad example:** "The login flow works correctly."

Write at least one statement per significant behaviour the feature introduces.

---

## Step 4 — Write failing tests (TDD)

Write tests that directly exercise each prove statement from Step 3. Then run the test suite and confirm:

1. The new tests exist and are syntactically valid
2. The new tests are **currently failing** (the feature is not yet implemented)

Do not proceed until failing tests are confirmed. If tests pass before implementation, the tests are not testing the right thing — fix them first.

**Red flags — STOP if you are thinking any of these:**

| Rationalization | Reality |
|----------------|---------|
| "Tests are hard to write for this" | That's the point — hard-to-test code reveals design problems. |
| "It's just a config change, not real code" | Config changes break things. They need tests. |
| "I'll write tests after to verify" | Tests written after implementation prove nothing new. |
| "The prove statements are enough verification" | Prove statements run after implementation. Tests must fail first. |
| "The feature is simple, tests would be trivial" | Trivial tests take 2 minutes. Skip them and you skip the discipline. |

**All of these mean: do not skip Step 4. Write failing tests first.**

---

## Step 5 — Implement the feature

Implement only what is needed to satisfy the prove statements and pass the tests. Do not over-engineer or add unrequested functionality.

For large features with clearly independent modules, invoke `superpowers:subagent-driven-development` to coordinate parallel execution across the independent parts. Give each sub-agent a specific, self-contained scope so their changes do not conflict.

**Every subagent prompt must include the feature branch name** created in Step 0 and an explicit instruction to commit only to that branch — never to `main` or `master`. Subagents do not inherit your branch context; you must tell them. Example line to include in each subagent prompt: *"All commits must go to branch `feature/my-feature`. Verify with `git branch --show-current` before committing."*

**After it completes, return to this pipeline. Continue to Step 6.**

---

## Step 6 — Simplify and re-run tests

Spawn the `code-simplifier:code-simplifier` agent on all files modified during implementation. It will refine the code for clarity, consistency, and maintainability while preserving all functionality.

After the code-simplifier completes, re-run the full test suite. Every test must pass before continuing. If simplification breaks any tests, fix them before proceeding.

---

## Step 7 — Prove each statement

For every statement in `.claude/prove_statements.md`, collect real, concrete evidence that it holds. Run the relevant command and capture actual output — do not assert something works without running it.

Then record the result for each prove statement using its name:

```
prove_it record --name <statement-name> --pass   # if verified
prove_it record --name <statement-name> --fail   # if not verified
```

Once all statements are verified, signal completion:

```
prove_it signal done
```

Address any failures before proceeding. Each statement must be backed by captured evidence.

---

## Step 8 — Code review

Invoke `superpowers:requesting-code-review` as a sub-step. It will spawn a code-reviewer covering all files modified in this session and check for: correctness, edge cases, security vulnerabilities, performance concerns, unclear naming, and missing error handling.

Address every issue raised. If you disagree with a suggestion and the reasoning is non-obvious, leave a brief inline comment explaining why. Re-run the test suite after any changes from this step. **After the review is addressed, return to this pipeline. Continue to Step 9.**

---

## Step 9 — Cleanup and create PR

Complete all of the following before creating the PR:

1. Remove debug logs, development TODOs, and any commented-out code left from the implementation
2. Run the project linter and fix all issues (e.g. `npm run lint`, `eslint .`, `ruff check --fix .`, or whatever is configured for this project)
3. Create the pull request in a draft state:

   ```
   gh pr create --draft --title "<concise imperative title>" --body "<what changed, why, and how to verify it>"
   ```

   The PR body must reference the prove statements from Step 3 and link to their evidence.
4. Open the PR with `open <url>` (macOS) or `xdg-open <url>` (Linux) in the default browser.

---

## Step 10 — Review loop

After the PR is created, check for review comments:

```
gh pr view --comments
```

For each unresolved review comment:

1. Address the feedback
2. Re-run tests to confirm nothing is broken
3. Push the updated branch
4. Re-check for new comments

Repeat until **both** conditions are true:
1. `gh pr view --comments` shows no unresolved review threads
2. The PR has a GitHub approval (visible in `gh pr view`) **or** the user explicitly says "merge it", "ship it", or equivalent

Do not self-declare the loop complete. The exit condition requires evidence from the above commands, not inference.

---

## Common Mistakes and Red Flags

**Pipeline shortcuts — STOP if you are thinking any of these:**

| Shortcut | Why it's wrong |
|----------|----------------|
| "Steps 6–8 are overhead once tests pass" | Simplification, proving, and review are non-negotiable pipeline stages. |
| "The user gave feedback, that means approval" | Feedback is not approval. Re-present the plan and wait for an explicit sign-off. |
| "The PR has been up for a while, it must be approved" | Check with `gh pr view`. Assume nothing. |
| "I already did a mental review, Step 8 is redundant" | The review is a formal sub-skill invocation, not a mental pass. |
| "There are no comments yet so the loop is done" | Both conditions (no threads AND approval/user sign-off) must be satisfied. |
| "I'm already on a branch, subagents will use it" | Subagents start fresh — they do not inherit your branch. Pass the branch name explicitly in every subagent prompt. |
| "I'll create the branch after planning" | By then a subagent may have already committed to master. Create the branch in Step 0, before anything else. |

**This pipeline is complete only when Step 11 has been executed. All steps are required.**

---

## Step 11 — Notify

Check whether the environment variable `SLACK_WEBHOOK` is set.

**If set:** Send a POST request to `$SLACK_WEBHOOK` with a JSON payload containing:

- The feature description
- PR URL (from `gh pr view --json url -q .url`)
- Test result summary
- Prove statement verification status
- Any items still requiring human attention

**If not set:** Print a clear terminal summary containing all of the above.
