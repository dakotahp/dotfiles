---
name: feature
description: Use when implementing an already-specified task: a ticket, a TRD section, or a written spec. Runs the full pipeline from spec validation through failing tests, implementation, review, and a draft PR. Expects the design to be settled and validates the spec against the code rather than working out what to build; given only an investigation or a rough idea, it asks for a specification first instead of designing one.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task
---

Implement the feature described in $ARGUMENTS by following every step below in order. Do not skip steps.

**The deliverable is a draft pull request whose automated signals are green.** Requesting reviews, marking the PR ready, and merging belong to the user. Do not do them, ask about them, or offer them. When Step 10's exit conditions hold, hand the PR over and stop.

**This skill is the master pipeline.** Other skills it invokes (writing-plans, subagent-driven-development, and so on) are sub-routines. When one finishes, return here and continue from the next step. When a subagent returns, re-read the current step's text, not the subagent's report, to decide what comes next.

**Lane mode.** If $ARGUMENTS contains `--lane`, this session was started by `/run-lanes` in the background, from an approved TRD ticket. Lane mode changes one thing: Step 2d does not wait for approval. Every other stop still waits, because the user can attach to the session and answer.

---

## Standing rules

The `feature-*` role definitions in `~/.config/claude/agents/` already carry the static rules: no code comments, no chaining gated commands, and verify only what you changed. Put these two in every dispatch prompt, with the values filled in:

1. **Worktree and branch.** *"Work only in `<worktree path>`. All commits must go to branch `feature/<slug>`. Verify with `git branch --show-current` before committing."*
2. **No nesting.** *"Do the work yourself. Do not delegate to further subagents."* You are the only agent that delegates. Dispatch exactly the roles a step names, with no extra reviewers or verifiers.

These apply to you as well:

- **Keep `git commit` and `git push` in their own Bash calls.** A chain prompts as a whole when any segment is gated, so a commit chained after tests stalls an unattended run. `cd <repo> && <allowlisted command>` is fine.
- **Verify at the point of change, once.** Whoever edits a file runs the narrowest test that covers it and lints only that file. Whoever edited nothing runs nothing. Never run the full suite; CI does that on push. A reviewer may run one test file to settle one specific suspicion, and must say why.

---

## Step 0: Session setup

### Dependencies

Confirm `gh`, `prove_it`, and the project's own tooling (README, `package.json` scripts, `Makefile`) are on PATH. Install anything missing (`brew install gh`, `brew install searlsco/tap/prove_it && prove_it install`). Do not run `prove_it init` or `prove_it reinit`; the worktree setup links the project's prove_it files instead.

### Worktree and feature branch

**Before any planning or code, work in a dedicated git worktree. No exceptions.** A feature branch in the main checkout is not enough, because the user and other sessions share that checkout.

Derive a kebab-case slug from $ARGUMENTS, with the ticket reference first when there is one (e.g. `app-1234-csv-export`). If the session is already in a worktree under `.claude/worktrees/`, keep it. `/run-lanes` starts lane sessions that way. Otherwise call the `EnterWorktree` tool with the slug as the name. Then rename the branch and confirm:

```bash
git branch -m feature/<slug>
```

Record the worktree path and branch name for every dispatch. Never commit to `main` or `master`.

### Link the prove_it files

The prove_it files are untracked, so a new worktree does not have them, and prove_it falls back to placeholder scripts. Link them from the main checkout so every worktree shares one copy, and keep the links out of `git status`:

```bash
main=$(git worktree list --porcelain | head -1 | cut -d' ' -f2)
exclude="$(git rev-parse --git-common-dir)/info/exclude"
for f in script/test script/test_fast .claude/prove_it/config.json .claude/rules/testing.md .claude/rules/done.md; do
  if [ -e "$main/$f" ] && [ ! -e "$f" ]; then mkdir -p "$(dirname "$f")" && ln -s "$main/$f" "$f"; fi
  if ! git ls-files --error-unmatch "$f" >/dev/null 2>&1; then grep -qxF "/$f" "$exclude" || echo "/$f" >> "$exclude"; fi
done
```

If `script/test_fast` is missing from the main checkout, or still says "No tests configured", stop and tell the user. **Never edit the linked files.** An edit writes through to every worktree. Above all, never make `script/test_fast` run the full suite: it runs on every stop and commit.

---

## Step 1 (optional): Start the ticket

If $ARGUMENTS references a ticket, use the tracker's MCP to assign it to me and move it to In Progress.

---

## Step 2: Establish the specification

### 2a: Identify what you were given

The input must be one of:

1. A ticket identifier or URL. Fetch it. If its description has a `TRD:` line, read that file too.
2. A path to a spec, TRD, or plan file. Read it. For a TRD ticket, read the whole TRD, since the ticket leans on its Interfaces and Behavior sections.
3. A TRD or technical plan produced earlier in this session. Use it, and do not re-ask what is settled.
4. Prose that states what changes, where, and how you would know it worked.

**If it is none of those, stop.** Say what is missing and offer to write a spec first. Do not design one from an investigation. The exception is an explicit request to design in-session: then run `superpowers:brainstorming` and treat its output as the spec.

### 2b: Validate the spec against the code

Skip this for a trivial single-file change. Otherwise, before any code exists, dispatch these read-only roles in one message so they run concurrently:

- **`plan-falsifier`**, with the path to the spec and nothing more. It marks every assumption about the existing system VERIFIED, FALSE, or UNVERIFIABLE, with `file:line` citations.
- **`plan-rederiver`**, only when the spec covers several interacting surfaces. Give it the verbatim requirements and nothing else, no spec path and no hint of the approach. Then diff its plan against the spec for missed areas and risks.

Scope both to falsifiable claims and coverage gaps, not design taste; the approach is settled upstream. Fold valid findings into the spec, and turn each UNVERIFIABLE assumption into an explicit verification task.

**A FALSE assumption is a stop, in lane mode too.** Take it to the user with the falsifier's evidence and wait. Fixing the spec is their call.

### 2c: Decompose into tasks

Invoke `superpowers:writing-plans` and tell it the approach is decided; its job is decomposition only. The plan lists the tasks in dependency order, each small enough for one subagent, with the files each touches and anything still unclear. Skip its "Execution Handoff" section; Step 5 controls execution.

Do not commit the spec or plan files. Step 8 deletes them.

### 2d: Get approval

Present the task breakdown, plus anything Step 2b made you correct or turn into a verification task, and ask for explicit approval. Feedback is not approval: revise and re-present. Close the message with a ready-to-run `/rename <TICKET> <slug>` so the session stays findable.

**Lane mode:** do not wait. The TRD ticket is already approved. Post the breakdown for the record and continue.

---

## Step 3: Write prove statements

Write `.claude/prove_statements.md`: concrete, falsifiable statements of what the feature will do, at least one per significant behavior. Each names the exact command and the exact output or exit code expected.

- Good: "`yarn test src/export.test.ts` exits 0 and reports 4 passed."
- Bad: "The export works."

Point each command at the behavior it covers, never at the whole suite; Step 6 runs these verbatim. If the file already has a statement with a broad command, the user wrote it on purpose, so leave it. End the step with one line naming the commands the statements will run, then continue.

---

## Step 4: Write failing tests

Write tests that exercise each prove statement. Run only the new test files and confirm they exist, parse, and **fail** because the feature is missing. A test that passes before implementation is testing the wrong thing, so fix it first.

If the plan contains copy-paste-ready test code, dispatch `feature-test-writer` with that code, the paths, and the command that runs those files. Otherwise write the tests yourself, because test design needs judgment.

---

## Step 5: Implement

Always use `superpowers:subagent-driven-development`, whatever the feature's size, so every task gets its own commit and review. Map its roles to these definitions:

| Step | Role | `subagent_type` |
|------|------|-----------------|
| 2b | Spec falsifier | `plan-falsifier` |
| 2b | Spec re-deriver | `plan-rederiver` |
| 4 | Test writer | `feature-test-writer` |
| 5 | Implementer | `feature-implementer` |
| 5 | Spec compliance review | `feature-spec-compliance` |
| 5 | Per-task quality review | `feature-task-reviewer` |
| 6 | Prove verifier | `feature-prove-verifier` |
| 7a | Cold diff review | `feature-adversarial-reviewer` |
| 7b | Branch coherence review | `feature-quality-reviewer` |
| 8 | Cleanup | `feature-cleanup` |
| 9, 10 | PR and review loop | **main session only** |

Dispatch by `subagent_type`. Each definition sets its own model, effort, and tools. Per task, dispatch `feature-implementer`, then `feature-spec-compliance` and `feature-task-reviewer` together in one message. The task reviewer also proposes simpler forms of dense code, and this is the pipeline's only simplification pass, so apply those findings too.

If a subagent returns BLOCKED, first add the missing context and re-dispatch. Only if the cause is reasoning difficulty, re-dispatch the same role with `model: opus`.

---

## Step 6: Prove each statement

Dispatch `feature-prove-verifier` with the full contents of `.claude/prove_statements.md`. It runs each command, records `prove_it record --name <n> --pass|--fail`, and calls `prove_it signal done`. If it reports a failure, diagnose and fix it, then re-dispatch.

---

## Step 7: Review

### 7a: Cold diff review

Dispatch `feature-adversarial-reviewer` with only the base branch name. Give it no plan, spec, or description of intent; inferring intent from the code is the point. Resolve the base from `git symbolic-ref --short refs/remotes/origin/HEAD` and pass the part after `origin/`. If that ref is missing, use whichever of `origin/main` or `origin/master` `git rev-parse --verify` resolves.

Fix every Critical and High finding. Use judgment on Medium. If you disagree with a finding, give the reason.

### 7b: Branch coherence review

After 7a is addressed, dispatch `feature-quality-reviewer` with the plan, the spec, and the changed files. It looks only for problems visible across tasks: contradictory invariants, drift from the plan, duplication, and requirements every task assumed another task covered. Address every issue, or leave a brief inline comment when the reason for not changing it is non-obvious.

After any fix in 7a or 7b, run the tests covering the files you changed.

---

## Step 8: Cleanup

Dispatch `feature-cleanup` with the changed files, the spec and plan paths to delete, and the lint command. It removes debug code, deletes the planning files, lints the changed files, and commits.

**Its report does not end the pipeline.** Continue to Step 9 in the same response.

---

## Step 9: Create the draft PR

Main session only.

```
gh pr create --draft --title "<concise imperative title>" --body "<what changed, why, how to verify>"
```

The body references the prove statements and their evidence. Open the URL with `xdg-open` (Linux) or `open` (macOS), and report the PR number and URL. Never run `gh pr ready`, `gh pr merge`, or `gh pr edit --add-reviewer`.

Step 10 needs a PR number from a `gh pr create` in this session. A PR found with `gh pr list` does not count.

---

## Step 10: Automated review loop

This loop watches the signals that land in minutes: CI, mergeability, and automated reviewer comments. It never waits for a human. Draft state does not block it.

Every poll makes both calls:

```
gh pr view <n> --json reviewDecision,comments,reviews,statusCheckRollup,mergeable,mergeStateStatus,baseRefName \
  --jq '{reviewDecision, mergeable, mergeStateStatus, baseRefName,
         comments:[.comments[]|{id, author:.author.login, at:.createdAt, body}],
         reviews:[.reviews[]|{author:.author.login, state, at:.submittedAt, body}],
         checks:[.statusCheckRollup[]?|{name:.name, status:.status, conclusion:.conclusion}]}'

gh api repos/{owner}/{repo}/pulls/<n>/comments --jq '.[]|{author:.user.login, path, line, body}'
```

Do not use `gh pr view --comments`; it truncates and omits inline comments. Reviewers differ by repo: some post one top-level comment, some post inline, some post a new comment per push, some edit one in place. Read both surfaces and key on the newest body per author.

Reading the results:

- A check whose `status` is not `COMPLETED` is still running.
- `mergeable: UNKNOWN` means GitHub has not decided yet. Poll again; it is not a pass.
- `mergeStateStatus: DRAFT` is expected. Read `mergeable` for conflicts. `BLOCKED` usually means a required check or review is pending, not a conflict.

Act in this order on every poll:

1. **`CONFLICTING`/`DIRTY` or `BEHIND`:** rebase first (below).
2. **A failing check:** diagnose, fix, test what you changed, push.
3. **Unaddressed review comments, bot or human:** evaluate on the merits, then fix and push or explain why not.
4. **More than one top-level comment from the same bot:** minimize all but the newest as outdated. Never touch a human's comment.

```
gh api graphql -f query='mutation($id: ID!) { minimizeComment(input: {subjectId: $id, classifier: OUTDATED}) { minimizedComment { isMinimized } } }' -f id="<comment id>"
```

### Rebasing

Rebase, never merge the base in. Confirm the branch, then:

```
git fetch origin <baseRefName>
git rebase origin/<baseRefName>
```

Resolve conflicts by keeping both sides; the other side is shipped work. Regenerate lockfiles instead of hand-merging them. Then re-run the prove statement commands, since the base moved under every file, and push with `git push --force-with-lease`, never `--force`. If the lease is rejected, someone else pushed: stop and tell the user.

If a resolution needs intent you do not have, or you are unsure, run `git rebase --abort` and tell the user which files conflicted and what each side wanted.

### Cadence and exit

If anything is still pending after you act, schedule the next poll with `ScheduleWakeup` at a fixed 180 seconds, re-running both calls. Stop when all three hold:

1. Every check is `COMPLETED` with no failing conclusion.
2. `mergeable` is `MERGEABLE`.
3. Every automated reviewer comment is addressed, on both surfaces.

Human approval is not a condition. Then post this and stop, with no offers or questions:

> **Pipeline complete.** Draft PR: `<url>`
> - CI: `<n>` checks passed
> - Mergeable: yes
> - Automated review: `<addressed / none posted>`
> - `reviewDecision`: `<value, or "none yet">`
>
> Yours from here: request reviews, mark ready, merge.

---

## Shortcuts that break this pipeline

| Thought | Reality |
|---------|---------|
| "This session already worked out the problem, that is a spec" | An investigation is not a spec. Step 2a stops. |
| "The feature is small, I'll implement inline" | Always subagent-driven-development. Inline work has no per-task commits or reviews. |
| "Let me re-run the suite to be sure" | Nothing changed since the last run. Run only what covers your own edits. |
| "Cleanup reported back, the work is done" | Step 9 creates the PR and Step 10 reviews it. You are two steps from done. |
| "Checks are green, so the PR is fine" | Also read `mergeable`. A conflicted branch cannot merge. |
| "The prove_it scripts are placeholders, I'll fill them in" | Stop and tell the user. The scripts are shared through links. |
