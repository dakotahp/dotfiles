---
name: feature
description: Full TDD feature development pipeline — checks deps, plans, writes prove statements, does TDD, implements, simplifies, proves, reviews, creates PR, handles review loop, and notifies when ready.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task
---

Implement the feature described in $ARGUMENTS by following every step below in order. Do not skip steps. Do not move to the next step until the current one is fully complete.

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

---

## Step 1 — Plan the feature

First, check whether Convext is configured for this project by testing all of the following:
1. The environment variable `CONVEXT_PROJECT_ID` is set, **or**
2. A file `.convext/config.json` or `.convext.json` exists in the project root, **or**
3. A `convext` key is present in `.claude/settings.json`

**If Convext is detected:** Use Convext task tracking to create and manage tasks for this feature. Break the work into discrete tasks in Convext and keep them updated throughout the pipeline. Note: if Convext commands are unavailable despite detection, fall back to plan mode and inform the user.

**If Convext is not configured (the default):** Enter plan mode. Present a detailed implementation plan covering:
- What will be created or changed and why
- Files to be added or modified
- Key architectural decisions and trade-offs
- Anything that needs clarification before work begins

Wait for explicit user approval before proceeding to Step 2.

---

## Step 2 — Write prove statements

Create or update the file `.claude/prove_statements.md` with concrete, falsifiable statements that describe what the implemented feature will do. Each statement must be:
- Specific and measurable — not "it works", but "running X produces Y"
- Independently verifiable using real commands or observable outputs
- Tied to a behaviour introduced by this feature

**Good example:** "`npm test` exits 0 and output contains 'auth › login: 3 passed, 0 failed'."
**Bad example:** "The login flow works correctly."

Write at least one statement per significant behaviour the feature introduces.

---

## Step 3 — Write failing tests (TDD)

Write tests that directly exercise each prove statement from Step 2. Then run the test suite and confirm:
1. The new tests exist and are syntactically valid
2. The new tests are **currently failing** (the feature is not yet implemented)

Do not proceed until failing tests are confirmed. If tests pass before implementation, the tests are not testing the right thing — fix them first.

---

## Step 4 — Implement the feature

Implement only what is needed to satisfy the prove statements and pass the tests. Do not over-engineer or add unrequested functionality.

For large features with clearly independent modules, spawn parallel sub-agents to work on separate parts simultaneously. Give each sub-agent a specific, self-contained scope so their changes do not conflict.

---

## Step 5 — Simplify and re-run tests

Spawn the `code-simplifier` agent on all files modified during implementation. It will refine the code for clarity, consistency, and maintainability while preserving all functionality.

After the code-simplifier completes, re-run the full test suite. Every test must pass before continuing. If simplification breaks any tests, fix them before proceeding.

---

## Step 6 — Prove each statement

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

## Step 7 — Code review

Spawn a code-reviewer sub-agent with the following instructions:
- Review all files modified in this session
- Check for: correctness, edge cases, security vulnerabilities, performance concerns, unclear naming, and missing error handling
- Return a prioritised list of all issues found

Address every issue raised. If you disagree with a suggestion and the reasoning is non-obvious, leave a brief inline comment explaining why. Re-run the test suite after any changes from this step.

---

## Step 8 — Cleanup and create PR

Complete all of the following before creating the PR:

1. Remove debug logs, development TODOs, and any commented-out code left from the implementation
2. Run the project linter and fix all issues (e.g. `npm run lint`, `eslint .`, `ruff check --fix .`, or whatever is configured for this project)
3. If Convext is configured, verify all tasks created in Step 1 are marked complete
4. Create the pull request:
   ```
   gh pr create --title "<concise imperative title>" --body "<what changed, why, and how to verify it>"
   ```
   The PR body must reference the prove statements from Step 2 and link to their evidence.

---

## Step 9 — Review loop

After the PR is created, check for review comments:
```
gh pr view --comments
```

For each unresolved review comment:
1. Address the feedback
2. Re-run tests to confirm nothing is broken
3. Push the updated branch
4. Re-check for new comments

Repeat until there are no unresolved comments and the PR is approved or explicitly marked ready to merge by the user.

---

## Step 10 — Notify

Check whether the environment variable `SLACK_WEBHOOK` is set.

**If set:** Send a POST request to `$SLACK_WEBHOOK` with a JSON payload containing:
- The feature description
- PR URL (from `gh pr view --json url -q .url`)
- Test result summary
- Prove statement verification status
- Any items still requiring human attention

**If not set:** Print a clear terminal summary containing all of the above.
