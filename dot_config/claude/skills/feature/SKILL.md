---
name: feature
description: Use when implementing an already-specified task: a ticket, a TRD section, or a written spec. Runs the full pipeline from spec validation through failing tests, implementation, review, and a draft PR. Expects the design to be settled and validates the spec against the code rather than working out what to build; given only an investigation or a rough idea, it asks for a specification first instead of designing one.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task
---

Implement the feature described in $ARGUMENTS by following every step below in order. Do not skip steps. Do not move to the next step until the current one is fully complete.

**This skill is the master pipeline.** All other skills invoked during this pipeline (brainstorming, writing-plans, subagent-driven-development, requesting-code-review, etc.) are sub-routines. After any sub-skill completes, immediately return to this pipeline and continue from the next numbered step. This pipeline is complete only when Step 10 has been executed.

---

## Standing rules for every subagent

These rules apply across the entire pipeline. They are defined once here; the steps below reference them by number instead of restating them.

**Rules 2, 3 and 5 are already baked into the role definitions** in `~/.config/claude/agents/feature-*.md` (see "Subagent roles" in Step 5), because their text is static. You do not need to restate them at dispatch. Rules 1 and 4 carry values only you know, so pass them in every dispatch prompt with the concrete values filled in.

**Rule 1: Commit only to the feature branch.** Applies to every subagent that writes or commits. Tell it the feature branch name created in Step 0 and instruct it to commit only to that branch, never to `main` or `master`. Include a line like: *"All commits must go to branch `feature/<name>`. Verify with `git branch --show-current` before committing."*

**Rule 2: Never bundle a gated command with others in one Bash call.** Applies to the main session and every subagent. The permission system *does* decompose compound commands: it splits on `&&`, `||`, `;`, `|`, and newlines and matches each segment against your allow/deny/ask rules independently. A chain auto-approves only when **every** segment matches an allow rule; if **any** segment is gated (commit, push, merge) or unmatchable, the whole chain prompts and you cannot approve just the safe half. So the rule is not "never chain"; it is: never join a gated or unmatchable step to safe ones. Concretely: (a) keep `git commit`/`git push`/`gh pr merge` in their own Bash calls, never chained after `git add`, tests, or a build; (b) `cd <repo> && <cmd>` is fine and encouraged when working from a parent dir, provided `<cmd>` is allowlisted; `cd` into the project tree or an `additionalDirectories` entry is auto-approved as read-only; (c) do not inline an `export VAR="...$HOME..."` or other expansion-bearing segment into a chain; it is unmatchable and forces a prompt for the whole chain (fix the environment at launch instead so the export is unnecessary). This keeps allowlisted reads, tests, lint, and builds running automatically while prompting only for genuinely sensitive actions.

**Rule 3: Default to no code comments.** Applies to every subagent that writes or edits code. Well-named identifiers and clear structure should make the code self-explanatory. Only add a comment when something is genuinely counter-intuitive on a rare basis, for example when a more idiomatic approach exists but cannot be used here for a specific reason, or when a future reader would otherwise be likely to "fix" the code without realizing why it is written this way. If a comment merely restates what the code does, delete it. Agents otherwise default to writing verbose, redundant comments.

**Rule 4: Do not spawn nested subagents.** Applies to every subagent you dispatch. Include this line: *"Do the work yourself. Do not delegate to further subagents."* Current Opus models reach for delegation readily, and each nested layer re-establishes context, re-explores the repo, and reports back through a summary the parent then re-reads. In a pipeline that already fans out per plan task, one unnecessary nesting layer can multiply token spend without improving the result. You, the orchestrator, are the only agent that delegates.

Applies to you as well, in one specific sense: dispatch exactly the roles the step calls for. Do not add extra reviewers, verifiers, or "second opinion" agents beyond what a step specifies. The pipeline's review coverage is deliberate, and Step 8 already runs two passes.

**Rule 5: Verify at the point of change, once.** Applies to the main session and every subagent. Tests and lint run when a file changes, run by whoever changed it, and are not re-run afterwards by anyone who did not change anything. Three parts:

- **If you edited files:** run the narrowest test command that covers them, and lint only the files you edited. Report the real output. "Narrowest" means the specific test file or its directory, never the suite: `bin/rails test test/models/foo_test.rb`, `yarn test src/foo.test.ts`, `go test ./pkg/foo`, `pytest tests/test_foo.py`.
- **If you edited nothing:** do not run tests and do not run a linter. Read the diff and the previous agent's reported results. Reviewers in this pipeline are read-only for a reason; a green run on a file nobody has touched since the last green run tells you nothing you were not already told.
- **Never run the project's full test suite.** Run only what covers your own edits, or, in Step 7, exactly the commands the prove statements name.

The narrow exception, for reviewers only: if you suspect a *specific* behavior is broken and one test file would settle it, run that one file and say in your report why you ran it. That is targeted evidence for a finding, not a re-verification pass.

**Why this rule exists.** A failing test or a lint violation is the one class of problem that is guaranteed to be caught anyway: CI runs the full suite and the linter on every push, in parallel, with nobody waiting on it. Local runs are therefore not the safety net, and a second local run of an unchanged file is not a safety net twice over. What CI cannot catch is everything the review passes exist for, so that is where this pipeline's time is worth spending. One earlier run spent it the other way: the linter ran five times and one slow seeded test four times, mostly on files unchanged between runs, while a genuinely untested controller went unnoticed until real CI found it.

---

## Step 0: Check and install dependencies

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

Derive the name from $ARGUMENTS (e.g. `feature/stripe-webhook`, `feature/phase4-security`). This branch is where every commit in this pipeline lands, including commits from subagents. Never commit to `main` or `master`. Record the branch name; you will pass it explicitly to every subagent you dispatch in Step 5.

### Session display name

From the same derivation, record a session display name: the ticket reference followed by the slug, without the `feature/` prefix. For branch `feature/app-1234-csv-export` that is `APP-1234 csv-export`. With no ticket reference, use the slug alone.

Deriving it from the branch slug rather than composing it separately is deliberate: it keeps the name in the session list matching the branch and the PR, so the agent view can be cross-referenced against them instead of only read.

You cannot set this yourself. There is no tool or hook for renaming a session, so you hand it to the user as a ready-to-run `/rename` in the Step 2 checkpoint, where they are already stopping to act. Record it now, while the ticket is in front of you.

---

## Step 1 (optional) - Start and assign ticket

If a ticket is being referenced, use the appropriate MCP to assign the ticket to me and move it into in progress.

---

## Step 2: Establish the specification

**This pipeline expects a defined task.** Its job is to implement a specification correctly, with TDD discipline and review, not to work out what should be built. Design belongs upstream, in `/technical-plan` and `/technical-requirements-document` or in a written ticket.

### Step 2a: Identify what you were given

Classify $ARGUMENTS, and the current session's context, into one of these:

1. **A ticket or issue identifier or URL.** Fetch it through the tracker's MCP.
2. **A path to a spec, TRD, or plan file.** Read it.
3. **A TRD or technical plan already produced in this session.** Use it plus the surrounding conversation, and do not re-ask what has already been settled.
4. **Prose that is genuinely a complete specification**, meaning it states what changes, where, and how you would know it worked.

**If it is none of those, stop.** Do not brainstorm your way to a specification, and do not infer one from an investigation earlier in the session. Say what is missing and offer to produce a spec first, for example: *"This is an investigation, not a specification. I can write a well-specified ticket from what we found, then run this pipeline against it. Want me to do that?"* An informal session is a poor input to this pipeline: it silently converts unreviewed assumptions into implemented code, and by the time that surfaces it costs a rewrite rather than a sentence.

The exception is an explicit request to design in-session. If the user asks for that, invoke `superpowers:brainstorming` first and treat its output as the specification, then continue from Step 2b. This is the exception, not the default path.

### Step 2b: Validate the specification against the code

A specification is a set of claims about a system, and claims can be wrong. Validating them before decomposing is what stops a false premise from becoming implemented behavior, and here it costs a sentence to fix rather than a rewrite.

Scale to the size of the spec: skip for a trivial single-file change; run both passes for anything spanning multiple files, surfaces, or subsystems. Dispatch them in a single message so they run concurrently. Both are read-only.

**Hard rules (each learned by getting it wrong):**
- **Run this before any implementation exists.** Once code is written, the reviewers rediscover your code instead of independently re-deriving intent, and the signal collapses.
- **Feed the reviewers the actual spec, not a hand-written summary.** A compressed summary makes them flag things the spec already covers ("it never mentions X" when it did).
- **Scope both to falsifiable claims and coverage gaps, not design taste.** The approach arrived from upstream and is not up for re-litigation here. Divergent-but-valid design is noise; false assumptions and missing risks are signal.

**Pass 1: Assumption falsification.** Dispatch `plan-falsifier` with the path to the spec. It enumerates every assumption the spec makes about the existing system and marks each VERIFIED, FALSE, or UNVERIFIABLE-WITHOUT-RUNTIME with a `file:line` citation. Its methodology lives in its definition; your prompt supplies the path and nothing more.

**Pass 2: Blind re-derivation.** Worth running when the spec covers a whole project or several interacting surfaces. Skip it for a single well-scoped ticket, where an independently derived plan has little to add. Dispatch `plan-rederiver` with the verbatim requirements **and nothing else**: no spec file path, no summary, no hint of the chosen approach. Then diff what it produced against the spec. Anything it surfaced that the spec omits, a missed affected area, an unstated risk, a dependency nobody named, is a gap in the spec.

Fold validated findings into the spec before decomposing. Convert each UNVERIFIABLE assumption into an explicit verification task rather than carrying it forward as though it were settled. Discard contamination artifacts and any finding that attacks a strawman.

**A FALSE assumption is a stop, not a footnote.** If the spec rests on something untrue of the code, the spec is wrong, and decomposing it produces tasks that cannot be implemented as written. Take it back to the user with what the falsifier found. That is a specification defect, and fixing it is their call, not something to paper over during implementation.

### Step 2c: Decompose into implementation tasks

Invoke `superpowers:writing-plans` to turn the validated specification into an ordered task breakdown. **The approach is already decided at this point; tell it so.** Its job here is decomposition, not design: which tasks, in what order, touching which files, with what verification. It must not re-litigate the approach the specification settled, and if it believes the approach is wrong, that is a finding to raise with the user, not a licence to substitute a different one.

The plan must cover:

- The tasks, in dependency order, each small enough for one subagent
- Files to be added or modified per task
- Anything still needing clarification before work begins

Later steps depend on this plan file existing: Step 5 executes it task by task and Step 9 deletes it.

**Do NOT commit the spec file or the plan file.** These are working artifacts; they are not part of the feature implementation and must not appear in the git history. Write them to disk, reference them throughout the pipeline, but never `git add` or commit them. They are deleted in Step 9 once their purpose is served.

**IMPORTANT:** Skip the writing-plans "Execution Handoff" section entirely; do NOT ask the user which execution approach to use. This pipeline controls execution flow; the writing-plans skill is a sub-routine here. Execution will use subagent-driven-development in Step 5.

### Step 2d: Get approval

**After writing-plans saves the plan file and the Step 2b findings are folded in**, present the task breakdown to the user and ask for explicit approval. Example: *"Implementation plan saved to `docs/superpowers/plans/<file>.md`. Here's a summary: [brief overview of tasks]. Approve the plan to continue, or give feedback to revise."* Do NOT end your message without this prompt: the writing-plans skill's natural ending is an execution handoff that you are skipping, so you must replace it with your own approval request.

Surface anything Step 2b turned up that you resolved by reading the code, and anything you converted into a verification task. The user approved the specification upstream, not your interpretation of it, so a spec claim you quietly corrected is exactly the thing they need to see here.

Approval means the user says something like "approved", "looks good", "proceed", or an unambiguous equivalent. **Feedback without approval is NOT approval**, incorporate the feedback, update the plan, and re-present it. Do not interpret silence or partial responses as approval. **After approval, immediately continue to Step 3 in the same response: do not wait for another user message.**

### Compaction checkpoint

**STOP. Do not continue to Step 3.** Context compaction must happen here but cannot be triggered automatically; only you can do it.

This is also the cheapest moment to change the orchestrator model, which is why the handoff bundles its asks. Prompt caches are scoped per model, so switching mid-session normally re-sends the entire conversation uncached; immediately after a `/compact` there is almost nothing left to re-warm. Because Step 2 validates a specification rather than designing one, the default tier is usually adequate for the whole run, so the switch matters mainly when this session started at a stronger tier for an unusually involved spec. Steps 3 through 7 are mostly dispatching roles and reading back short summaries.

Post this message verbatim, then wait for the user to respond before doing anything else:

> **Handoff: Step 2 complete. Action required before continuing.**
> - Branch: `<branch name>`
> - Spec file: `<path>`
> - Plan file: `<path>`
> - Next step: Step 3
> - Open issues: `<any user caveats or scope notes from approval>`
>
> **Please run these, then reply "continue":**
> - `/compact`, to clear the spec-validation and planning context
> - `/rename <session display name>`, so this session stays findable in the session list once several are open
> - optionally `/model sonnet`, if this session started at a stronger tier: Steps 3 through 7 are dispatch-heavy, and switching right after a compact costs almost nothing in cache

**Fill in the actual display name recorded in Step 0.** Posting the placeholder defeats the purpose, since the whole point is that the user does not have to compose the name themselves.

Do not proceed to Step 3 until the user explicitly replies. If they decline the rename or the model switch, continue exactly as normal; nothing downstream depends on either.

---

## Step 3: Write prove statements

Create or update the file `.claude/prove_statements.md` with concrete, falsifiable statements that describe what the implemented feature will do. Each statement must be:

- Specific and measurable, not "it works", but "running X produces Y"
- Independently verifiable using real commands or observable outputs
- Tied to a behaviour introduced by this feature

**Good example:** "`npm test` exits 0 and output contains 'auth › login: 3 passed, 0 failed'."
**Bad example:** "The login flow works correctly."

Write at least one statement per significant behaviour the feature introduces.

Statements are the contract Step 7 verifies against, so vagueness here is not recoverable later: a statement that cannot fail cannot prove anything. If you switched to a mid-tier model at the Step 2 checkpoint, re-read each statement and ask what output would falsify it. Name the exact command and the exact string or exit code you expect.

### Scope each command to the feature

**Point every command at the behaviour its statement describes**, not at the project. A statement covering a presenter names that presenter's test file; one covering an endpoint names that endpoint's test. Targeted commands are what makes a failure in Step 7 legible: when the command that failed runs one file, its output says what broke, and when it runs the whole project the answer is buried in everything that did not.

Do not author a statement whose command runs the project's whole test suite. Step 7 executes these commands verbatim, so a statement like that becomes an unbounded local run in the middle of the pipeline, and CI already covers the same ground on push without anyone waiting on it.

If `.claude/prove_statements.md` already contains a statement naming a broad command, leave it exactly as written and run it. The user maintains that file and tunes those commands themselves; a statement you did not write is a deliberate choice, not an oversight to correct.

When you finish this step, state in one line which commands the statements will run before continuing to Step 4. Do not stop for approval; this is a notice, not a gate.

---

## Step 4: Write failing tests (TDD)

Write tests that directly exercise each prove statement from Step 3. Then run **only the new test files** (Standing Rule 5) and confirm:

1. The new tests exist and are syntactically valid
2. The new tests are **currently failing** (the feature is not yet implemented)

Running the whole suite here proves nothing extra: every other test in the project passed before you wrote a file, and will pass after. Point the runner at the paths you just created.

Do not proceed until failing tests are confirmed. If tests pass before implementation, the tests are not testing the right thing, fix them first.

**Delegation:** If the plan contains exact test code (copy-paste ready), dispatch `feature-test-writer`. Its prompt must include: Standing Rules 1 and 4 with the branch name filled in, the exact test code from the plan, the paths to write it to, and the command that runs **those specific files**. If the plan does NOT contain exact test code (only describes behaviors), write the tests in the main session, test design requires judgment.

**Red flags: STOP if you are thinking any of these:**

| Rationalization | Reality |
|----------------|---------|
| "Tests are hard to write for this" | That's the point, hard-to-test code reveals design problems. |
| "It's just a config change, not real code" | Config changes break things. They need tests. |
| "I'll write tests after to verify" | Tests written after implementation prove nothing new. |
| "The prove statements are enough verification" | Prove statements run after implementation. Tests must fail first. |
| "The feature is simple, tests would be trivial" | Trivial tests take 2 minutes. Skip them and you skip the discipline. |

**All of these mean: do not skip Step 4. Write failing tests first.**

---

## Step 5: Implement the feature

Implement only what is needed to satisfy the prove statements and pass the tests. Do not over-engineer or add unrequested functionality.

**Always invoke `superpowers:subagent-driven-development`** to implement the plan task-by-task. This is not optional, inline implementation in the main session has no per-task commit discipline and no review checkpoints between tasks, which defeats the pipeline's purpose regardless of feature size. Give each sub-agent a specific, self-contained scope (one task from the plan) so their changes do not conflict.

Map that sub-skill's roles onto these definitions: `feature-implementer` for the per-task implementer, then `feature-spec-compliance` and `feature-task-reviewer` for the per-task review checkpoint. Dispatch the two reviewers together in one message so they run concurrently; they read the same diff and do not depend on each other.

Every dispatch prompt must carry Standing Rule 1 (commit only to the feature branch) with the actual branch name filled in, and Standing Rule 4 (do not spawn nested subagents). Rules 2 and 3 are already in the definitions.

### Subagent roles

**Dispatch by `subagent_type`, not by `model`.** Each role is a definition file in `~/.config/claude/agents/`, and it owns that role's model, reasoning effort, tool scope, and static instructions. This table governs the **entire pipeline**, not just Step 5:

| Step | Role | `subagent_type` | Model + effort |
|------|------|-----------------|----------------|
| 2b | Spec assumption-falsifier | `plan-falsifier` | sonnet / high |
| 2b | Spec re-deriver | `plan-rederiver` | sonnet / high |
| 4 | Test writer | `feature-test-writer` | sonnet / medium |
| 5 | Implementer | `feature-implementer` | sonnet / high |
| 5 | Spec compliance reviewer | `feature-spec-compliance` | haiku / low |
| 5 | Per-task quality reviewer | `feature-task-reviewer` | sonnet / high |
| 6 | Code simplifier | `code-simplifier:code-simplifier` | sonnet, session effort |
| 7 | Prove verifier | `feature-prove-verifier` | haiku / low |
| 8a | Adversarial diff reviewer | `feature-adversarial-reviewer` | sonnet / high |
| 8b | Branch coherence reviewer | `feature-quality-reviewer` | sonnet / high |
| 9 | Cleanup (pre-PR) | `feature-cleanup` | sonnet / medium |

**Why the definitions exist rather than inline `model` arguments.** Reasoning effort is the larger cost lever here, and the Task tool has no `effort` parameter. A subagent inherits the *session* effort unless its definition overrides it, so with a session-wide `effortLevel` of `xhigh`, a haiku agent running `prove_it record` also ran at `xhigh`. Effort drives thinking and output tokens, billed at several times the input rate, and the subagents are where this pipeline's token volume lives. Per-role effort is only expressible in a definition file, which is why these roles are files.

Two secondary wins: the read-only tool scoping that Step 8 depends on is declared in `tools` frontmatter instead of relying on you to pass it, and each role's static instructions live in its own body rather than being reproduced in this skill on every pipeline turn.

**Escalation:** If a subagent returns BLOCKED and the cause is reasoning difficulty rather than missing context, re-dispatch the same `subagent_type` with `model: opus` to override the definition for that one call. Try adding the missing context first; most BLOCKED reports are a context problem wearing a reasoning problem's clothes.

**Step 6 is the exception.** `code-simplifier:code-simplifier` is a plugin agent whose definition carries no `effort` key, so it inherits session effort and cannot be tuned from here. Leave it; do not fork the plugin's prompt into a local definition just to set effort on it.

**When NOT to delegate:** Steps 2 (establishing the spec) and 3 (prove statements) require understanding the design spec and translating requirements into falsifiable claims. These stay in the main session. The one exception inside Step 2 is the Step 2b pair: delegate the two read-only reviewers, but keep the diff, the synthesis, and the spec revision with you.

**Context window benefit:** Subagent results return as short summaries, not raw tool output. A haiku agent running 10 prove_it commands keeps ~50 lines of test output out of the orchestrator's context. Over a full pipeline run, this compounds significantly.

**After it completes, return to this pipeline. Continue to Step 6.**

### Compaction checkpoint

**STOP. Do not continue to Step 6.** Context compaction must happen here but cannot be triggered automatically, only you can do it.

Post this message verbatim, then wait for the user to respond before doing anything else:

> **Handoff: Step 5 complete. Action required before continuing.**
> - Branch: `<branch name>`
> - Plan file: `<path>`
> - Prove statements: `.claude/prove_statements.md`
> - Implementation status: all plan tasks implemented, code committed
> - Test status: `<pass/fail summary from subagent runs>`
> - Next step: Step 6
> - Open issues: `<any known gaps or deferred items>`
>
> **Please run `/compact` now to clear the implementation context. If you switched to `/model sonnet` earlier, this is the other cheap moment to switch back: Step 8 synthesis (deciding which review findings to accept and articulating why) is the remaining judgment-heavy work. Staying on sonnet through Step 9 is also fine, and you can escalate later if 8a returns Critical findings. Reply "continue" when done to proceed to Step 6.**

Do not proceed to Step 6 until the user explicitly replies after compacting.

---

## Step 6: Simplify and re-run tests

Spawn the `code-simplifier:code-simplifier` agent on all files modified during implementation. It will refine the code for clarity, consistency, and maintainability while preserving all functionality. This is the one role whose effort you cannot tune (see "Step 6 is the exception" under Subagent roles in Step 5); dispatch it as-is.

**Pass Standing Rule 5 in this dispatch prompt.** This is a plugin agent, so unlike the `feature-*` roles it has no local definition carrying the rule, and left alone it will re-run the suite and re-lint the branch it just read. Tell it: run the narrowest tests covering the files it actually changed, lint only those files, and run nothing at all for files it read but left alone.

Its report tells you which files it changed and whether their tests passed. **Do not re-run anything yourself.** Simplification is refactoring, so its blast radius is the files it edited, and it already verified them. If it reports a failure it could not fix, fix that before continuing; that is the only reason to run a test in this step.

---

## Step 7: Prove each statement

For every statement in `.claude/prove_statements.md`, collect real, concrete evidence that it holds. Run the relevant command and capture actual output, do not assert something works without running it.

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

**Delegation:** Dispatch `feature-prove-verifier`. Its prompt must include the full contents of `.claude/prove_statements.md` plus Standing Rules 1 and 4 with the branch name filled in. It runs each verification command, records pass or fail, calls `prove_it signal done`, and reports BLOCKED with the actual output if any statement fails so the main session can diagnose and fix. Keeping this out of the main session also keeps full test output out of the main context.

---

## Step 8: Code review

This step runs **two distinct review passes** with different framings. Both are required. They catch different classes of issues and one cannot substitute for the other.

### 8a: Adversarial diff review (big-picture)

The goal of this pass is to catch the kind of show-stopper issues a cold PR reviewer would catch: unintended behavior changes, scope creep, architectural regressions, missing coverage for edge cases the implementation silently introduced, contract/API changes the author didn't realize they made.

Dispatch `feature-adversarial-reviewer` with **no session context, no plan, no spec, no prove statements**. Its prompt carries exactly two things: the diff base branch name, and Standing Rule 4. Nothing else. The role must not be told what the feature is "supposed" to do; it must infer intent from the code itself, the way a PR reviewer does. This cold framing is the entire point, and this is the one dispatch in the pipeline where adding helpful context makes the result strictly worse.

The review categories, the skip list, and the output format all live in the role definition, so there is no verbatim prompt to reproduce here. Resist the urge to restate them: a paraphrase in your dispatch prompt competes with the definition instead of reinforcing it.

**Diff base:** resolve the repo's actual default branch with `git remote show origin | sed -n 's/.*HEAD branch: //p'` (commonly `main`, sometimes `master`) and pass that name.

**Read-only is structural, not advisory.** The role's `tools` frontmatter grants `Read, Glob, Grep, Bash` and no `Write` or `Edit`, so it cannot alter the branch whatever it runs. That is what makes its verification commands safe to auto-approve (see the read-only settings note at the end of this step). You do not need to pass tool restrictions at dispatch, and you should not override them.

Address every Critical and High finding. For Medium findings, use judgment. If you disagree with a finding, you must articulate why, disagreement requires reasoning, not dismissal. After any change you make, run the tests covering the files you changed (Standing Rule 5). If you changed nothing, run nothing.

### 8b: Branch coherence review (cross-task)

After 8a is fully addressed, dispatch `feature-quality-reviewer`. Unlike 8a, this pass gets full context: pass it the plan, the spec, and the list of modified files, plus Standing Rule 4.

**This pass is deliberately narrow, and the narrowing is the point.** It looks only for problems that appear when the tasks are viewed together: one task contradicting an invariant another relies on, tasks that individually match the plan but collectively drift from it, duplication grown independently in two places, a contract between two tasks where each side is locally correct, a spec requirement every task assumed a different task covered. General code quality is **not** its job. Step 5 already reviewed each task's diff as it landed, and 8a already read the whole branch cold. A third general quality pass re-derives their findings and buries anything genuinely new.

It is read-only by definition, same as 8a, so its verification runs autonomously and it cannot mutate the branch. You, not the reviewer, apply any fixes.

Address every issue raised. If you disagree with a suggestion and the reasoning is non-obvious, leave a brief inline comment explaining why. After any change you make, run the tests covering the files you changed (Standing Rule 5). If you changed nothing, run nothing.

**Why three review lenses, and why they do not collapse:** the per-task reviewer in Step 5 sees one diff in isolation and catches ordinary defects while the context is still fresh. 8a sees the whole branch with no knowledge of intent, which is what surfaces accidental behavior changes and scope creep; a reviewer who knows what the code was supposed to do rationalizes those away. 8b sees the whole branch *with* intent, which is the only vantage point from which cross-task interactions are visible at all. Each lens is blind to what the others catch. What does not need a third pass is per-task quality, which is why 8b is scoped away from it rather than deleted: the redundancy was in 8b's old breadth, not in its existence.

### Autonomous verification without approval-babysitting

Both reviewers run *arbitrary* read commands (diffs, greps, log queries, ad-hoc one-liners, and under Standing Rule 5's narrow exception the occasional single test file), so a static command allowlist can never cover all of it, and a `dontAsk` mode would auto-DENY anything unlisted and break the review mid-run. Two mechanisms keep the reviewers autonomous AND safe; they compose:

1. **Read-only tool scoping** (above): with no `Edit`/`Write`/`Agent` tool, a reviewer cannot mutate the branch no matter what it runs, so auto-approving its reads/tests is safe by construction.
2. **Sandbox mode** for the Bash it does run: OS-level confinement (writes limited to the workspace, network denied) lets contained commands execute without a prompt; only network/escaping commands fall back to asking. Your user settings (`~/.claude/settings.json`, or `$CLAUDE_CONFIG_DIR/settings.json` if that is set) should carry, once:
   ```json
   {
     "sandbox": { "enabled": true, "autoAllowBashIfSandboxed": true },
     "permissions": {
       "allow": ["Read","Grep","Glob","Bash(git diff *)","Bash(git log *)","Bash(git show *)","Bash(git status *)","Bash(npm test *)","Bash(go test *)","Bash(pytest *)","Bash(gh pr view *)","Bash(gh pr checks *)","Bash(gh api *)","Bash(gh pr diff:*)","Bash(bin/rubocop:*)","Bash(bin/rails:*)","Bash(bin/rake:*)","Bash(bundle exec:*)","Bash(yarn:*)"],
       "ask": ["Bash(git push:*)","Bash(git commit:*)"],
       "deny": ["Bash(git reset *)","Bash(rm *)","Bash(gh pr merge *)"],
       "additionalDirectories": ["/absolute/path/to/repo-a","/absolute/path/to/repo-b"]
     }
   }
   ```
   Deny always wins over allow, so destructive gates hold; `ask` on commit/push keeps those in the loop without a hard block. **When running this pipeline from a parent dir above sibling repos**, list each repo in `additionalDirectories` (this makes `cd <repo>` auto-approved as read-only and lets file tools operate there) and allowlist the per-repo dev commands (`bin/rubocop`, `bin/rails`, `yarn`, etc.) as bare prefixes, so `cd <repo> && <cmd>` chains auto-approve segment by segment. Also ensure the launcher's PATH already carries what commands need (e.g. mise shims) so agents never inline an `export`, see Rule 2. Never use `bypassPermissions` for reviewers (containers only).

**After both passes are addressed, return to this pipeline. Continue to Step 9.**

---

## Step 9: Cleanup and create PR

Complete all of the following before creating the PR:

1. Remove debug logs, development TODOs, and any commented-out code left from the implementation
2. **Discard the planning artifacts.** The spec file and plan file from Step 2 have served their purpose, implementation is done, both review passes are complete, and the PR body (next step) will capture the lasting context. Delete both files from disk now. If the conversation needs to revisit design decisions later, the chat history and PR body are sufficient.
3. Run the project linter over the files this branch changed (`git diff --name-only <base>...HEAD`) and fix all issues (e.g. `npm run lint`, `eslint`, `ruff check --fix`, `bin/rubocop`, or whatever is configured for this project). **This is the branch's one lint gate**, and under Standing Rule 5 it is the only lint run in the pipeline that is not scoped to a single agent's own edits. Pass the linter the changed paths rather than the repo root: a whole-repo run reports pre-existing violations this branch did not cause, which you then have to sort back out.
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

**Delegation:** Steps 1-3 (cleanup, planning-artifact deletion, linting) can be dispatched to `feature-cleanup`. Its prompt must include: Standing Rules 1 and 4 with the branch name filled in, the list of modified files, the paths to the spec and plan files to delete, and the lint command for the project. Step 4 (PR creation) stays in the main session, the PR title and body require understanding the full feature context, and the user needs to see the PR URL immediately.

---

## Step 10: Review loop

**Draft state does not block this step.** Run this loop against the PR immediately, whether or not it has been marked ready for review. Automated reviewer bots (e.g. a `claude-review`/`claude-review-inline` CI check) run on draft PRs the same as on ready ones, and CI (build/lint/tests) starts on push regardless of draft state. Catching feedback before ready-for-review is the point, not a reason to wait. Only a human reviewer requiring the PR to be out of draft before they'll look at it would be a reason to wait, and that is the user's call to make, not a default assumption.

**This step always polls both CI and review feedback together, on a fixed cadence, until both exit conditions hold.** This is not optional and not left to judgment per run: every poll checks both surfaces in the same pass, and every poll that leaves anything outstanding schedules the next one. An agent that checks CI but not comments, or comments but not CI, or checks once and reports status without scheduling a follow-up, has not run this step correctly.

After the PR is created, check for review feedback and CI status together. **Do NOT use `gh pr view --comments`**, the pretty format is truncated and unparseable, and it silently omits line-anchored review comments, so it forces a re-run. Review feedback lives on three separate surfaces, and CI status is a fourth thing to check every time; pull all of them directly as JSON in two calls:

```
# 1) Top-level conversation comments + formal review summaries + the merge-gate decision + CI checks:
gh pr view <n> --json reviewDecision,comments,reviews,statusCheckRollup \
  --jq '{reviewDecision,
         comments:[.comments[]|{author:.author.login, at:.createdAt, body}],
         reviews:[.reviews[]|{author:.author.login, state, at:.submittedAt, body}],
         checks:[.statusCheckRollup[]?|{name:.name, status:.status, conclusion:.conclusion}]}'

# 2) Inline (line-anchored) review comments: NOT returned by `gh pr view`:
gh api repos/{owner}/{repo}/pulls/<n>/comments \
  --jq '.[]|{author:.user.login, path, line, body}'
```
(`{owner}/{repo}` auto-substitute from the current repo; no interpolation.)

**Repo review setups differ: the same two calls cover all of them, but interpret results accordingly:**
- Some repos' Claude reviewer posts **one big top-level comment** (surface 1); others post **inline comments on specific lines** (surface 2). Always read both surfaces; do not assume which one a repo uses.
- Some reviewers **post a new comment per commit** (compare by `createdAt`; the newest is current). Others **amend the same comment in place** (`createdAt` never changes across re-reviews: fetch the latest **body** by author, e.g. `select(.author.login=="claude")`, rather than trusting timestamps). Handle both by keying on author + newest body, not on comment count or time.
- `checks` entries with `status` other than `COMPLETED` (e.g. `QUEUED`, `IN_PROGRESS`) are still running — not a failure, and not a reason to stop polling.

**On every poll, act on what you found before deciding whether to poll again:**
- A check's `conclusion` is `FAILURE` (or similar, e.g. `CANCELLED`, `TIMED_OUT`): diagnose it yourself, fix it, re-run the tests covering the change, and push. Do not just report the failure and wait for it to be fixed some other way — fixing broken CI is this step's job.
- There is unaddressed review feedback on either surface — most often the automated `claude-review`/`claude-review-inline` bot, but treat a human reviewer's comments the same way: evaluate it on its merits (per `superpowers:receiving-code-review` if the feedback is substantive), fix and push if it's valid, or articulate why you disagree if it's not. Never dismiss feedback without reasoning, and never treat a bot comment as lower-stakes than a human one.
- After addressing anything, re-fetch with the two calls above (add `select(.createdAt > "<last-check-ISO>")` to see only what is new) before deciding the loop is done.

**Polling cadence:** if, after acting on the above, either exit condition below is not yet met — a check is still running, no formal review has landed yet, or you just pushed a fix and want to see it land — schedule the next combined poll with `ScheduleWakeup` at a **fixed 180-second (3-minute) interval**. Do not shorten it because "CI is usually fast" and do not lengthen it because "this might take a while" — 3 minutes is the ceiling the user should ever have to wait for a status update, and consistency here matters more than shaving polls. The `ScheduleWakeup` prompt must re-run this exact combined check (both CI and review feedback, both gh calls) every time, never a partial check of just one surface. Keep scheduling wakeups across as many 3-minute intervals as it takes; do not give up after one round just because nothing changed.

Repeat until **both** conditions are true:
1. No unresolved review threads across **both** surfaces above, and no CI check left in a non-`COMPLETED` state.
2. `reviewDecision` is `APPROVED` **or** the user explicitly says "merge it", "ship it", or equivalent. (`reviewDecision` is the machine-readable gate; `REVIEW_REQUIRED`/`CHANGES_REQUESTED` means not yet.)

Do not self-declare the loop complete. The exit condition requires evidence from the commands above, not inference.

**Marking the PR ready for review, and merging it, are always the user's action, never yours.** This isn't a permission gate to ask about each time, it's a standing division of labor: the user handles both unconditionally. When the loop's exit condition is met, report that plainly (checks green, no unresolved threads, reviewDecision/explicit go-ahead status) and stop there — don't ask whether to mark ready or merge, and don't run `gh pr ready` or `gh pr merge` yourself. If the exit condition is met purely because there is nothing left to check (all checks green, no reviewer assigned, no reviewDecision possible), say so plainly and stop polling rather than scheduling wakeups indefinitely with nothing new to look for.

---

## Common Mistakes and Red Flags

**Pipeline shortcuts: STOP if you are thinking any of these:**

| Shortcut | Why it's wrong |
|----------|----------------|
| "Steps 6–8 are overhead once tests pass" | Simplification, proving, and review are non-negotiable pipeline stages. |
| "The user gave feedback, that means approval" | Feedback is not approval. Re-present the plan and wait for an explicit sign-off. |
| "The PR has been up for a while, it must be approved" | Check with `gh pr view`. Assume nothing. |
| "I already did a mental review, Step 8 is redundant" | The review is a formal sub-skill invocation, not a mental pass. |
| "There are no comments yet so the loop is done" | Both conditions (no threads AND approval/user sign-off) must be satisfied. |
| "I'm already on a branch, subagents will use it" | Subagents start fresh, they do not inherit your branch. Pass the branch name explicitly in every subagent prompt. |
| "I'll create the branch after planning" | By then a subagent may have already committed to master. Create the branch in Step 0, before anything else. |
| "This feature is small, inline execution is fine" | Feature size is irrelevant. Inline execution has no per-task commits and no review checkpoints. Always use subagent-driven-development. |
| "The spec is obviously right, skip the validation" | A false premise in the spec becomes implemented behavior, and by then it costs a rewrite. Run Step 2b before approval, on the real spec, before any code exists. |
| "This session already figured out the problem, that counts as a spec" | It does not. An investigation is not a specification, and Step 2a stops rather than brainstorming. Write the ticket first, then run the pipeline against it. |
| "Chaining commands into one Bash call is faster" | Fine for all-allowlisted segments (`cd <repo> && <allowlisted cmd>`), but the moment one segment is gated (commit/push) or unmatchable (an inline `export`), the whole chain prompts and unattended runs stall. Standing Rule 2: never bundle a gated or unmatchable step with others. |
| "Let me just re-run the suite to be sure before I continue" | Sure of what? Nothing has changed since the last agent ran it. Standing Rule 5: if you did not edit a file, you do not test it. The reassurance is real, the information is zero, and the wall clock is the same either way. |
| "I only changed one file, but I'll run the whole suite anyway, it's safer" | It is not safer, it is slower and it buries the result you actually needed in output nobody reads. Run the narrowest command covering what you changed; CI runs the rest on push. |
| "This reviewer found something, it should verify by running the tests" | Only if one specific test file would settle one specific suspicion, and only with a note saying why. A reviewer running the suite is re-verifying, not investigating. |
| "The linter should run here too, it's cheap" | It is cheap once and wasteful five times. Editors lint their own edits; Step 9 lints the branch. Nowhere else. |
| "I checked CI, I'll check comments next time" / "I checked comments, CI is probably still running" | Step 10 checks both surfaces every single poll, no exceptions. Checking one and deferring the other is why this step used to be inconsistent. |
| "No feedback yet, I'll just stop checking" | If either exit condition isn't met, schedule a `ScheduleWakeup` at 180s and check again. Silence isn't the exit condition; evidence of green checks + approval/go-ahead is. |

**This pipeline is complete only when Step 10 has been executed. All steps are required.**
