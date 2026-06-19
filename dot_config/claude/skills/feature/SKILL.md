---
name: feature
description: Use when implementing a new feature from scratch, before writing any implementation code.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task
---

Implement the feature described in $ARGUMENTS by following every step below in order. Do not skip steps. Do not move to the next step until the current one is fully complete.

**This skill is the master pipeline.** All other skills invoked during this pipeline (brainstorming, writing-plans, subagent-driven-development, requesting-code-review, etc.) are sub-routines. After any sub-skill completes, immediately return to this pipeline and continue from the next numbered step. This pipeline is complete only when Step 10 has been executed.

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

Invoke `superpowers:brainstorming` as a sub-step to explore requirements and design space. When doing so, instruct it to **skip the "User Review Gate" for the written spec** — the plan approval at the end of this step serves as the combined spec+plan gate, so asking the user to separately review the spec file is redundant here. After brainstorming writes the spec, it should proceed directly to invoking writing-plans without pausing for spec review.

**Do NOT commit the spec file or the plan file.** These planning documents are working artifacts — they are not part of the feature implementation and must not appear in the git history. Write them to disk, reference them throughout the pipeline, but never `git add` or commit them. They will be deleted in Step 9 once their purpose is served.

After brainstorming completes, invoke `superpowers:writing-plans` to produce the implementation plan. The plan must cover:

- What will be created or changed and why
- Files to be added or modified
- Key architectural decisions and trade-offs
- Anything that needs clarification before work begins

**IMPORTANT:** Skip the writing-plans "Execution Handoff" section entirely — do NOT ask the user which execution approach to use. This pipeline controls execution flow; the writing-plans skill is a sub-routine here. Execution will use subagent-driven-development in Step 5.

### Adversarial plan review (run BEFORE asking for approval)

Stress-test the plan the way Step 8 stress-tests the diff, but catch the blind spots now, when they cost a sentence to fix instead of a rewrite. Scale to plan size: skip for a trivial single-file plan; run both passes for anything spanning multiple files, surfaces, or subsystems. Both passes are read-only `sonnet` subagents, dispatched in parallel.

**Hard rules (each learned by getting it wrong):**
- **Run this before any implementation exists.** Once code is written, the reviewers rediscover your code instead of independently re-deriving intent, and the signal collapses.
- **Feed the reviewer the actual plan + spec files, not a hand-written summary.** A compressed summary makes the reviewer flag things the plan already covers ("the plan never mentions X" when it did).
- **Scope both reviewers to falsifiable claims and coverage gaps, not design taste.** Divergent-but-valid design is noise; false assumptions and missing risks are signal.

**Pass 1 — Assumption falsification (grounded).** Give it the plan + spec + the repo. Prompt verbatim:

> You are stress-testing a TECHNICAL PLAN before it is implemented, against the real codebase. Read the plan and spec at <paths> and explore the repo. (1) Enumerate every assumption the plan makes about the existing system, including implicit ones it never states. (2) For each, verify against actual code/schema/config and mark VERIFIED (file:line), FALSE (file:line), or UNVERIFIABLE-WITHOUT-RUNTIME (a genuine unknown needing a spike). (3) Flag anything that would make a step fail as written — a seam that does not exist, an export/data path that is not what the plan assumes, an aggregation that cannot be added where claimed. Focus on falsifiable facts about the existing system, not design taste. End with a ranked "biggest blind spots / verify before building" list.

**Pass 2 — Blind re-derivation.** Give it ONLY the spec/ticket requirements + the repo, NOT the plan. Prompt verbatim:

> Produce an independent technical plan for the requirements below, from scratch. Do not assume an existing plan exists; derive everything from the requirements and the codebase, verifying claims in code. Cover: what each key term actually maps to in this codebase (trace it, cite file:line; watch for similarly-named decoys), whether the needed data already exists or must be built, the backend/frontend/export seam for each requirement, risks and unknowns you could not confirm, and a build order. Requirements: <verbatim ticket/spec text>.

Then **you** diff Pass 2's plan against yours: anything it surfaced that yours omitted — a missed approach, an unstated risk, a whole affected area — is a blind spot. Pass 1 finds "this specific thing will break"; Pass 2 finds "you framed this wrong or missed an area." They are complementary; run both.

Fold validated findings back into the plan and spec before presenting them. Convert each UNVERIFIABLE assumption into an explicit spike/verification task rather than an optimistic claim. Discard contamination artifacts and any finding that attacks a strawman of the plan.

**After writing-plans saves the plan file and the plan review above is folded in**, present a summary of the plan to the user and ask for explicit approval. Example: *"Implementation plan saved to `docs/superpowers/plans/<file>.md`. Here's a summary: [brief overview of tasks]. Approve the plan to continue, or give feedback to revise."* Do NOT end your message without this prompt — the writing-plans skill's natural ending is an execution handoff that you are skipping, so you must replace it with your own approval request.

Approval means the user says something like "approved", "looks good", "proceed", or an unambiguous equivalent. **Feedback without approval is NOT approval** — incorporate the feedback, update the plan, and re-present it. Do not interpret silence or partial responses as approval. **After approval, immediately continue to Step 3 in the same response — do not wait for another user message.**

### Compaction checkpoint

**STOP. Do not continue to Step 3.** Context compaction must happen here but cannot be triggered automatically — only you can do it.

Post this message verbatim, then wait for the user to respond before doing anything else:

> **Handoff — Step 2 complete. Action required before continuing.**
> - Branch: `<branch name>`
> - Spec file: `<path>`
> - Plan file: `<path>`
> - Next step: Step 3
> - Open issues: `<any user caveats or scope notes from approval>`
>
> **Please run `/compact` now to clear the brainstorming/planning context, then reply "continue" to proceed to Step 3.**

Do not proceed to Step 3 until the user explicitly replies after compacting.

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

**Delegation:** If the plan contains exact test code (copy-paste ready), dispatch a `sonnet` subagent to write the test files and verify they fail. The subagent prompt must include: the branch name, the exact test code from the plan, the command to run tests, and the instruction to confirm tests fail with specific error messages. If the plan does NOT contain exact test code (only describes behaviors), write the tests in the main session — test design requires judgment.

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

### Code comments

Default to no comments. Well-named identifiers and clear structure should make the code self-explanatory to both humans and agents reading it later. Only add a comment when something is genuinely counter-intuitive on a rare basis — for example, a more idiomatic approach exists but cannot be used here for a specific reason, or a future reader would otherwise be likely to "fix" the code without realizing why it is written this way. If a comment merely restates what the code does, delete it. **Every subagent prompt in this step must include this rule verbatim**, because agents otherwise default to writing verbose, redundant comments.

**Always invoke `superpowers:subagent-driven-development`** to implement the plan task-by-task. This is not optional — inline implementation in the main session has no per-task commit discipline and no review checkpoints between tasks, which defeats the pipeline's purpose regardless of feature size. Give each sub-agent a specific, self-contained scope (one task from the plan) so their changes do not conflict.

**Every subagent prompt must include the feature branch name** created in Step 0 and an explicit instruction to commit only to that branch — never to `main` or `master`. Subagents do not inherit your branch context; you must tell them. Example line to include in each subagent prompt: *"All commits must go to branch `feature/my-feature`. Verify with `git branch --show-current` before committing."*

### Subagent model tiers

To conserve cost, speed, and context window hygiene, use the `model` parameter when dispatching subagents. This table governs the **entire pipeline**, not just Step 5:

| Step | Role | Model | Rationale |
|------|------|-------|-----------|
| 2.5 | **Plan assumption-falsifier** | `sonnet` | Codebase-grounded verification of the plan's claims |
| 2.5 | **Plan re-deriver** | `sonnet` | Independent plan from the spec; reasoning, but well-scoped |
| 4 | **Test writer** | `sonnet` | Plan contains exact test code; writing + verifying failure is mechanical |
| 5 | **Implementer** | `sonnet` | Mechanical work with clear specs from the plan |
| 5 | **Spec compliance reviewer** | `haiku` | Pure checklist comparison — does code match spec? |
| 5 | **Code quality reviewer** | `sonnet` | Judgment needed but well-scoped to a single task's diff |
| 6 | **Code simplifier** | `sonnet` | Refinement within clear conventions, not invention |
| 7 | **Prove verifier** | `haiku` | Rote command execution: run command, check output, record pass/fail |
| 8a | **Adversarial diff reviewer** | `sonnet` | Cold review of full branch diff — needs reasoning to spot behavior changes and architectural regressions |
| 8b | **Code-quality reviewer** | `sonnet` | Warm review with full context — judgment scoped to a known diff with clear conventions |
| 9 | **Cleanup & PR creator** | `sonnet` | Linting, removing debug code, calling `gh pr create` is mechanical |

**Escalation:** If any subagent returns BLOCKED and the cause is reasoning difficulty (not missing context), re-dispatch with `model: opus`.

**When NOT to delegate:** Steps 2 (planning) and 3 (prove statements) require understanding the design spec and translating requirements into falsifiable claims. These stay in the main session. The one exception inside Step 2 is the plan-review pair: delegate the two read-only reviewers, but keep the diff/synthesis and the plan revision with you.

**Context window benefit:** Subagent results return as short summaries, not raw tool output. A haiku agent running 10 prove_it commands keeps ~50 lines of test output out of the main opus context. Over a full pipeline run, this compounds significantly.

**After it completes, return to this pipeline. Continue to Step 6.**

### Compaction checkpoint

**STOP. Do not continue to Step 6.** Context compaction must happen here but cannot be triggered automatically — only you can do it.

Post this message verbatim, then wait for the user to respond before doing anything else:

> **Handoff — Step 5 complete. Action required before continuing.**
> - Branch: `<branch name>`
> - Plan file: `<path>`
> - Prove statements: `.claude/prove_statements.md`
> - Implementation status: all plan tasks implemented, code committed
> - Test status: `<pass/fail summary from subagent runs>`
> - Next step: Step 6
> - Open issues: `<any known gaps or deferred items>`
>
> **Please run `/compact` now to clear the implementation context, then reply "continue" to proceed to Step 6.**

Do not proceed to Step 6 until the user explicitly replies after compacting.

---

## Step 6 — Simplify and re-run tests

Spawn the `code-simplifier:code-simplifier` agent (with `model: sonnet`) on all files modified during implementation. It will refine the code for clarity, consistency, and maintainability while preserving all functionality.

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

**Delegation:** Dispatch a `haiku` subagent to handle prove verification. The subagent prompt must include: the full contents of `.claude/prove_statements.md`, the branch name, and instructions to run each verification command, check the output, and call `prove_it record` + `prove_it signal done`. If any statement fails, the subagent must report BLOCKED with the failure details so the main session can diagnose and fix. This is pure command execution — haiku is sufficient and keeps test output out of the main context.

---

## Step 8 — Code review

This step runs **two distinct review passes** with different framings. Both are required. They catch different classes of issues and one cannot substitute for the other.

### 8a — Adversarial diff review (big-picture)

The goal of this pass is to catch the kind of show-stopper issues a cold PR reviewer would catch: unintended behavior changes, scope creep, architectural regressions, missing coverage for edge cases the implementation silently introduced, contract/API changes the author didn't realize they made.

Dispatch a `sonnet` subagent with **no session context, no plan, no spec, no prove statements** — only the diff against `master` and the ability to read the repo as it stands. The subagent must not be told what the feature is "supposed" to do; it must infer intent from the code itself, the way a PR reviewer does. This cold framing is the entire point — do not include the plan file path, the spec, or a description of the feature in the prompt.

The subagent prompt must include verbatim:

> You are reviewing a branch diff against `master` as a skeptical, cold reviewer. You have no prior context on this change. Your job is to find real problems a senior engineer would flag, not style nits.
>
> ### Step 1: Gather context
>
> Run `git diff master...HEAD` to see all changed lines. Read whatever files you need from the working tree to understand the change in context. Infer intent from the code itself — do not ask for a spec or plan.
>
> ### Step 2: Look for these issue categories
>
> - **Security vulnerabilities** — injection, auth bypass, data exposure, insecure defaults
> - **Error handling gaps** — unhandled exceptions, missing null checks, swallowed errors
> - **Race conditions and concurrency issues** — shared mutable state, missing locks, TOCTOU
> - **API misuse or anti-patterns** — wrong method for the job, deprecated usage, contract violations
> - **Architecture concerns** — wrong abstraction level, violating existing patterns in the codebase, duplicating something that already exists
> - **User experience and usability issues** — confusing workflows, missing user feedback (loading states, error messages, success confirmations), broken UI states, accessibility problems, data displayed incorrectly or misleadingly, poor error messaging that doesn't help the user recover
> - **Data integrity issues** — incorrect data transformations, missing validations at system boundaries (user input, external APIs), stale cache problems, inconsistent state
> - **Root cause vs symptom** — fixes that patch over a symptom while the underlying problem remains, workarounds that will need to be reworked later
> - **Behavior changes and scope creep** — code paths quietly altered that don't appear central to the change, or code that doesn't belong with the apparent purpose
> - **Contract / API changes** — function signatures, return types, error shapes, schema fields, public exports that downstream callers may rely on
> - **Missing tests** for behaviors the diff introduces or changes, especially edge cases and failure paths (only when a critical path is untested)
>
> ### Step 3: Skip these
>
> Do NOT comment on:
> - Style or formatting (linters handle this)
> - Missing documentation or tests, unless a critical path is untested
> - Compliments or positive feedback
> - Pre-existing issues (only review new/changed lines)
> - Things a linter, typechecker, or CI would catch (imports, type errors, formatting)
> - Something that looks like a bug but is not actually a bug on closer inspection
> - Pedantic nitpicks that a senior engineer wouldn't call out
> - General code quality issues (test coverage, documentation) unless they directly impact users
> - Changes in functionality that are likely intentional or directly related to the broader change
> - Issues that are explicitly silenced in the code (lint ignore comments, intentional workarounds with explanatory comments)
>
> ### Step 4: Output format
>
> Write one entry per finding in this exact format:
>
> ```
> ### [Critical/High/Medium] - Short title
> **File:** path/to/file.ext:line
> **Issue:** Description of the problem
> **Why it matters:** Impact if not fixed
> **Suggestion:** How to fix
> ```
>
> If you find nothing material, say so explicitly — do not invent findings to seem useful.

Address every Critical and High finding. For Medium findings, use judgment. If you disagree with a finding, you must articulate why — disagreement requires reasoning, not dismissal. Re-run the test suite after any changes.

### 8b — Code-quality review (small-picture)

After 8a is fully addressed, dispatch a second `sonnet` subagent for a conventional quality review. This pass has full session context (plan, spec, modified files) and focuses on: correctness within the intended design, edge cases, security vulnerabilities, performance, unclear naming, missing error handling, deprecated APIs, idiomatic patterns.

Address every issue raised. If you disagree with a suggestion and the reasoning is non-obvious, leave a brief inline comment explaining why. Re-run the test suite after any changes from this step.

**Why two passes:** 8a runs cold to mimic the mindset of a PR reviewer who has no investment in the change — this is what surfaces show-stoppers like accidental behavior changes and scope creep. 8b runs warm because code-quality judgments (naming, idioms, edge cases within the intended design) benefit from understanding what the code is trying to do. Collapsing them into one pass produces sycophantic reviews that catch nits but miss architecture.

**After both passes are addressed, return to this pipeline. Continue to Step 9.**

---

## Step 9 — Cleanup and create PR

Complete all of the following before creating the PR:

1. Remove debug logs, development TODOs, and any commented-out code left from the implementation
2. **Discard the planning artifacts.** The spec file and plan file from Step 2 have served their purpose — implementation is done, both review passes are complete, and the PR body (next step) will capture the lasting context. Delete both files from disk now. If the conversation needs to revisit design decisions later, the chat history and PR body are sufficient.
3. Run the project linter and fix all issues (e.g. `npm run lint`, `eslint .`, `ruff check --fix .`, or whatever is configured for this project)
4. Create the pull request in a draft state:

   ```
   gh pr create --draft --title "<concise imperative title>" --body "<what changed, why, and how to verify it>"
   ```

   When merging a PR, always use a merge commit (not squash or rebase):

   ```
   gh pr merge <number> --merge --delete-branch
   ```

   The PR body must reference the prove statements from Step 3 and link to their evidence.
5. Open the PR with `open <url>` (macOS) or `xdg-open <url>` (Linux) in the default browser.

**Delegation:** Steps 1-3 (cleanup, planning-artifact deletion, linting) can be dispatched to a `sonnet` subagent. The subagent prompt must include: the branch name, the list of modified files, the paths to the spec and plan files to delete, the lint command for the project, and instructions to fix any issues and commit the cleanup (the deleted planning files were never tracked, so they will simply disappear from disk — no git operation needed for them). Step 4 (PR creation) should stay in the main session — the PR title and body require understanding the full feature context, and the user needs to see the PR URL immediately.

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
| "This feature is small, inline execution is fine" | Feature size is irrelevant. Inline execution has no per-task commits and no review checkpoints. Always use subagent-driven-development. |
| "The plan is obviously right, skip the plan review" | Plan-stage blind spots are the cheapest to fix and the most expensive to discover mid-implementation. Run the Step 2 plan review before approval, on the full plan, before any code exists. |

**This pipeline is complete only when Step 10 has been executed. All steps are required.**
