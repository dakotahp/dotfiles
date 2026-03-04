---
name: feature
description: Full TDD feature development pipeline — checks deps, plans, writes prove statements, does TDD, implements, simplifies, proves, reviews, creates PR, handles review loop, and notifies when ready.
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

Wait for explicit user approval before continuing. **After approval, return to this pipeline. Continue to Step 3.**

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

---

## Step 5 — Implement the feature

Implement only what is needed to satisfy the prove statements and pass the tests. Do not over-engineer or add unrequested functionality.

For large features with clearly independent modules, invoke `superpowers:subagent-driven-development` to coordinate parallel execution across the independent parts. Give each sub-agent a specific, self-contained scope so their changes do not conflict. **After it completes, return to this pipeline. Continue to Step 6.**

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

Repeat until there are no unresolved comments and the PR is approved or explicitly marked ready to merge by the user.

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
