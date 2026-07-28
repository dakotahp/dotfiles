---
name: feature
description: Use when implementing a new feature from scratch, before writing any implementation code.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task
---

Implement the feature described in $ARGUMENTS by following every step below in order. Do not skip steps. Do not move to the next step until the current one is fully complete.

**This skill is the master pipeline.** All other skills invoked during this pipeline (brainstorming, writing-plans, subagent-driven-development, requesting-code-review, etc.) are sub-routines. After any sub-skill completes, immediately return to this pipeline and continue from the next numbered step. This pipeline is complete only when Step 10 has been executed.

---

## Standing rules for every subagent

These rules apply across the entire pipeline. They are defined once here; the steps below reference them by number instead of restating them.

**Rules 2 and 3 are already baked into the role definitions** in `~/.config/claude/agents/feature-*.md` (see "Subagent roles" in Step 5), because their text is static. You do not need to restate them at dispatch. Rules 1 and 4 carry values only you know, so pass them in every dispatch prompt with the concrete values filled in.

**Rule 1: Commit only to the feature branch.** Applies to every subagent that writes or commits. Tell it the feature branch name created in Step 0 and instruct it to commit only to that branch, never to `main` or `master`. Include a line like: *"All commits must go to branch `feature/<name>`. Verify with `git branch --show-current` before committing."*

**Rule 2: Never bundle a gated command with others in one Bash call.** Applies to the main session and every subagent. The permission system *does* decompose compound commands: it splits on `&&`, `||`, `;`, `|`, and newlines and matches each segment against your allow/deny/ask rules independently. A chain auto-approves only when **every** segment matches an allow rule; if **any** segment is gated (commit, push, merge) or unmatchable, the whole chain prompts and you cannot approve just the safe half. So the rule is not "never chain"; it is: never join a gated or unmatchable step to safe ones. Concretely: (a) keep `git commit`/`git push`/`gh pr merge` in their own Bash calls, never chained after `git add`, tests, or a build; (b) `cd <repo> && <cmd>` is fine and encouraged when working from a parent dir, provided `<cmd>` is allowlisted; `cd` into the project tree or an `additionalDirectories` entry is auto-approved as read-only; (c) do not inline an `export VAR="...$HOME..."` or other expansion-bearing segment into a chain; it is unmatchable and forces a prompt for the whole chain (fix the environment at launch instead so the export is unnecessary). This keeps allowlisted reads, tests, lint, and builds running automatically while prompting only for genuinely sensitive actions.

**Rule 3: Default to no code comments.** Applies to every subagent that writes or edits code. Well-named identifiers and clear structure should make the code self-explanatory. Only add a comment when something is genuinely counter-intuitive on a rare basis, for example when a more idiomatic approach exists but cannot be used here for a specific reason, or when a future reader would otherwise be likely to "fix" the code without realizing why it is written this way. If a comment merely restates what the code does, delete it. Agents otherwise default to writing verbose, redundant comments.

**Rule 4: Do not spawn nested subagents.** Applies to every subagent you dispatch. Include this line: *"Do the work yourself. Do not delegate to further subagents."* Current Opus models reach for delegation readily, and each nested layer re-establishes context, re-explores the repo, and reports back through a summary the parent then re-reads. In a pipeline that already fans out per plan task, one unnecessary nesting layer can multiply token spend without improving the result. You, the orchestrator, are the only agent that delegates.

Applies to you as well, in one specific sense: dispatch exactly the roles the step calls for. Do not add extra reviewers, verifiers, or "second opinion" agents beyond what a step specifies. The pipeline's review coverage is deliberate, and Step 8 already runs two passes.

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

---

## Step 1 (optional) - Start and assign ticket

If a ticket is being referenced, use the appropriate MCP to assign the ticket to me and move it into in progress.

---

## Step 2: Plan the feature

Invoke `superpowers:brainstorming` as a sub-step to explore requirements and design space. When doing so, instruct it to **skip the "User Review Gate" for the written spec**, the plan approval at the end of this step serves as the combined spec+plan gate, so asking the user to separately review the spec file is redundant here. After brainstorming writes the spec, it should proceed directly to invoking writing-plans without pausing for spec review.

**Do NOT commit the spec file or the plan file.** These planning documents are working artifacts; they are not part of the feature implementation and must not appear in the git history. Write them to disk, reference them throughout the pipeline, but never `git add` or commit them. They will be deleted in Step 9 once their purpose is served.

After brainstorming completes, invoke `superpowers:writing-plans` to produce the implementation plan. The plan must cover:

- What will be created or changed and why
- Files to be added or modified
- Key architectural decisions and trade-offs
- Anything that needs clarification before work begins

**IMPORTANT:** Skip the writing-plans "Execution Handoff" section entirely; do NOT ask the user which execution approach to use. This pipeline controls execution flow; the writing-plans skill is a sub-routine here. Execution will use subagent-driven-development in Step 5.

### Adversarial plan review (run BEFORE asking for approval)

Stress-test the plan the way Step 8 stress-tests the diff, but catch the blind spots now, when they cost a sentence to fix instead of a rewrite. Scale to plan size: skip for a trivial single-file plan; run both passes for anything spanning multiple files, surfaces, or subsystems. Both passes are read-only roles, dispatched in parallel in a single message so they run concurrently.

**Hard rules (each learned by getting it wrong):**
- **Run this before any implementation exists.** Once code is written, the reviewers rediscover your code instead of independently re-deriving intent, and the signal collapses.
- **Feed the reviewer the actual plan + spec files, not a hand-written summary.** A compressed summary makes the reviewer flag things the plan already covers ("the plan never mentions X" when it did).
- **Scope both reviewers to falsifiable claims and coverage gaps, not design taste.** Divergent-but-valid design is noise; false assumptions and missing risks are signal.

**Pass 1: Assumption falsification (grounded).** Dispatch `feature-plan-falsifier`. Pass it only the paths to the plan file and the spec file. Its methodology lives in its definition; your prompt supplies the paths and nothing more.

**Pass 2: Blind re-derivation.** Dispatch `feature-plan-rederiver`. Pass it the verbatim ticket or spec requirements **and nothing else**. Do not pass the plan file path, a summary of the plan, or any hint of the approach you chose. Its whole value is deriving the plan independently, and a single sentence describing your intended design collapses the comparison. The role will flag contamination if it sees any, but do not rely on that; get the dispatch right.

Then **you** diff Pass 2's plan against yours: anything it surfaced that yours omitted, a missed approach, an unstated risk, a whole affected area, is a blind spot. Pass 1 finds "this specific thing will break"; Pass 2 finds "you framed this wrong or missed an area." They are complementary; run both.

Fold validated findings back into the plan and spec before presenting them. Convert each UNVERIFIABLE assumption into an explicit spike/verification task rather than an optimistic claim. Discard contamination artifacts and any finding that attacks a strawman of the plan.

**After writing-plans saves the plan file and the plan review above is folded in**, present a summary of the plan to the user and ask for explicit approval. Example: *"Implementation plan saved to `docs/superpowers/plans/<file>.md`. Here's a summary: [brief overview of tasks]. Approve the plan to continue, or give feedback to revise."* Do NOT end your message without this prompt: the writing-plans skill's natural ending is an execution handoff that you are skipping, so you must replace it with your own approval request.

Approval means the user says something like "approved", "looks good", "proceed", or an unambiguous equivalent. **Feedback without approval is NOT approval**, incorporate the feedback, update the plan, and re-present it. Do not interpret silence or partial responses as approval. **After approval, immediately continue to Step 3 in the same response: do not wait for another user message.**

### Compaction checkpoint

**STOP. Do not continue to Step 3.** Context compaction must happen here but cannot be triggered automatically; only you can do it.

This checkpoint is also the cheapest moment in the whole pipeline to change the orchestrator model, which is why the handoff asks for both. Prompt caches are scoped per model, so switching mid-session normally re-sends the entire conversation uncached. Immediately after a `/compact` there is almost nothing left to re-warm, so the switch is close to free. Steps 0 through 2 want the stronger model: brainstorming is interactive, and diffing Pass 2's independent plan against yours is the highest-judgment act in the pipeline. Steps 3 through 7 are mostly dispatching roles and reading back short summaries, which a mid-tier model handles at a lower rate per token.

Post this message verbatim, then wait for the user to respond before doing anything else:

> **Handoff: Step 2 complete. Action required before continuing.**
> - Branch: `<branch name>`
> - Spec file: `<path>`
> - Plan file: `<path>`
> - Next step: Step 3
> - Open issues: `<any user caveats or scope notes from approval>`
>
> **Please run `/compact` now to clear the brainstorming/planning context. Then, optionally, run `/model sonnet` before replying: Steps 3 through 7 are dispatch-heavy and do not need the stronger model, and switching right after a compact costs almost nothing in cache. Reply "continue" when done to proceed to Step 3.**

Do not proceed to Step 3 until the user explicitly replies after compacting. If the user declines the model switch, continue exactly as normal; nothing downstream depends on it.

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

---

## Step 4: Write failing tests (TDD)

Write tests that directly exercise each prove statement from Step 3. Then run the test suite and confirm:

1. The new tests exist and are syntactically valid
2. The new tests are **currently failing** (the feature is not yet implemented)

Do not proceed until failing tests are confirmed. If tests pass before implementation, the tests are not testing the right thing, fix them first.

**Delegation:** If the plan contains exact test code (copy-paste ready), dispatch `feature-test-writer`. Its prompt must include: Standing Rules 1 and 4 with the branch name filled in, the exact test code from the plan, the paths to write it to, and the command to run tests. If the plan does NOT contain exact test code (only describes behaviors), write the tests in the main session, test design requires judgment.

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
| 2.5 | Plan assumption-falsifier | `feature-plan-falsifier` | sonnet / high |
| 2.5 | Plan re-deriver | `feature-plan-rederiver` | sonnet / high |
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

**When NOT to delegate:** Steps 2 (planning) and 3 (prove statements) require understanding the design spec and translating requirements into falsifiable claims. These stay in the main session. The one exception inside Step 2 is the plan-review pair: delegate the two read-only reviewers, but keep the diff/synthesis and the plan revision with you.

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

After the code-simplifier completes, re-run the full test suite. Every test must pass before continuing. If simplification breaks any tests, fix them before proceeding.

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

Address every Critical and High finding. For Medium findings, use judgment. If you disagree with a finding, you must articulate why, disagreement requires reasoning, not dismissal. Re-run the test suite after any changes.

### 8b: Branch coherence review (cross-task)

After 8a is fully addressed, dispatch `feature-quality-reviewer`. Unlike 8a, this pass gets full context: pass it the plan, the spec, and the list of modified files, plus Standing Rule 4.

**This pass is deliberately narrow, and the narrowing is the point.** It looks only for problems that appear when the tasks are viewed together: one task contradicting an invariant another relies on, tasks that individually match the plan but collectively drift from it, duplication grown independently in two places, a contract between two tasks where each side is locally correct, a spec requirement every task assumed a different task covered. General code quality is **not** its job. Step 5 already reviewed each task's diff as it landed, and 8a already read the whole branch cold. A third general quality pass re-derives their findings and buries anything genuinely new.

It is read-only by definition, same as 8a, so its verification runs autonomously and it cannot mutate the branch. You, not the reviewer, apply any fixes.

Address every issue raised. If you disagree with a suggestion and the reasoning is non-obvious, leave a brief inline comment explaining why. Re-run the test suite after any changes from this step.

**Why three review lenses, and why they do not collapse:** the per-task reviewer in Step 5 sees one diff in isolation and catches ordinary defects while the context is still fresh. 8a sees the whole branch with no knowledge of intent, which is what surfaces accidental behavior changes and scope creep; a reviewer who knows what the code was supposed to do rationalizes those away. 8b sees the whole branch *with* intent, which is the only vantage point from which cross-task interactions are visible at all. Each lens is blind to what the others catch. What does not need a third pass is per-task quality, which is why 8b is scoped away from it rather than deleted: the redundancy was in 8b's old breadth, not in its existence.

### Autonomous verification without approval-babysitting

Both reviewers run *arbitrary* verification code (diffs, greps, test suites, ad-hoc one-liners), so a static command allowlist can never cover all of it, and a `dontAsk` mode would auto-DENY anything unlisted and break the review mid-run. Two mechanisms keep the reviewers autonomous AND safe; they compose:

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

**Delegation:** Steps 1-3 (cleanup, planning-artifact deletion, linting) can be dispatched to `feature-cleanup`. Its prompt must include: Standing Rules 1 and 4 with the branch name filled in, the list of modified files, the paths to the spec and plan files to delete, and the lint command for the project. Step 4 (PR creation) stays in the main session, the PR title and body require understanding the full feature context, and the user needs to see the PR URL immediately.

---

## Step 10: Review loop

After the PR is created, check for review feedback. **Do NOT use `gh pr view --comments`**, the pretty format is truncated and unparseable, and it silently omits line-anchored review comments, so it forces a re-run. Review feedback lives on three separate surfaces; pull all of them directly as JSON in two calls:

```
# 1) Top-level conversation comments + formal review summaries + the merge-gate decision:
gh pr view <n> --json reviewDecision,comments,reviews \
  --jq '{reviewDecision,
         comments:[.comments[]|{author:.author.login, at:.createdAt, body}],
         reviews:[.reviews[]|{author:.author.login, state, at:.submittedAt, body}]}'

# 2) Inline (line-anchored) review comments: NOT returned by `gh pr view`:
gh api repos/{owner}/{repo}/pulls/<n>/comments \
  --jq '.[]|{author:.user.login, path, line, body}'
```
(`{owner}/{repo}` auto-substitute from the current repo; no interpolation.)

**Repo review setups differ: the same two calls cover all of them, but interpret results accordingly:**
- Some repos' Claude reviewer posts **one big top-level comment** (surface 1); others post **inline comments on specific lines** (surface 2). Always read both surfaces; do not assume which one a repo uses.
- Some reviewers **post a new comment per commit** (compare by `createdAt`; the newest is current). Others **amend the same comment in place** (`createdAt` never changes across re-reviews: fetch the latest **body** by author, e.g. `select(.author.login=="claude")`, rather than trusting timestamps). Handle both by keying on author + newest body, not on comment count or time.

For each unresolved item: address it, re-run the tests covering the change, push, then re-fetch with the two calls above (add `select(.createdAt > "<last-check-ISO>")` to see only what is new).

Repeat until **both** conditions are true:
1. No unresolved review threads across **both** surfaces above.
2. `reviewDecision` is `APPROVED` **or** the user explicitly says "merge it", "ship it", or equivalent. (`reviewDecision` is the machine-readable gate; `REVIEW_REQUIRED`/`CHANGES_REQUESTED` means not yet.)

Do not self-declare the loop complete. The exit condition requires evidence from the commands above, not inference.

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
| "The plan is obviously right, skip the plan review" | Plan-stage blind spots are the cheapest to fix and the most expensive to discover mid-implementation. Run the Step 2 plan review before approval, on the full plan, before any code exists. |
| "Chaining commands into one Bash call is faster" | Fine for all-allowlisted segments (`cd <repo> && <allowlisted cmd>`), but the moment one segment is gated (commit/push) or unmatchable (an inline `export`), the whole chain prompts and unattended runs stall. Standing Rule 2: never bundle a gated or unmatchable step with others. |

**This pipeline is complete only when Step 10 has been executed. All steps are required.**
