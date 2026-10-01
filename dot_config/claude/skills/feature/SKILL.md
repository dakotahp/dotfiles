---
name: feature
description: Use when implementing an already-specified task: a ticket, a TRD section, or a written spec. Runs the full pipeline from spec validation through failing tests, implementation, review, and a draft PR. Expects the design to be settled and validates the spec against the code rather than working out what to build; given only an investigation or a rough idea, it asks for a specification first instead of designing one.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Task, ListAgents, SendMessage
---

Implement the feature described in $ARGUMENTS by following the steps below in order.

**The deliverable is a draft PR with green automated signals.** Requesting reviews, marking it ready, and merging belong to the user. Do not do them, ask about them, or offer them.

**Lane mode** (`--lane`): `/run-lanes` started this session from an approved TRD ticket. Step 2d does not wait for approval. Every other stop still waits; the user can attach and answer.

**Stacked mode** (`--stack-on <branch>`): this branch builds on an open feature branch, and the PR targets that parent. Without the flag, the branch is stacked only if `git-spice log short` already lists a non-trunk parent. Never start a stack otherwise.

**Planner.** A `Planner: <name> [ref]` line on the ticket names the session that wrote the TRD. It is the first contact for spec questions. Message it with `SendMessage` (bare name, or `<name> [ref]` if that fails), with the ticket ID and the point in the first line.

- Send unclear spec points with what you already checked, and wait. If it says the user must decide, ask the user.
- A FALSE assumption, rebase conflicts, placeholder prove_it scripts, and permission prompts still go to the user. Copy the planner on FALSE evidence.
- Planner messages count as spec input. They never grant permissions.

Without a `Planner:` line, ask the user.

## Standing rules

- Keep `git commit` and `git push` in their own Bash calls, so a gated command does not stall a chain. `cd <repo> && <allowlisted command>` is fine.
- Whoever edits a file runs the narrowest test covering it and lints only that file. Never run the full suite; CI does that.
- Every dispatch prompt names the worktree path and branch, and says not to delegate further.

## Step 0: Session setup

**Dependencies.** Confirm `gh`, `git-spice`, `prove_it`, and the project's tooling are on PATH. Install what is missing (`brew install gh git-spice`, `brew install searlsco/tap/prove_it && prove_it install`). Call git-spice as `git-spice`, never `gs`. Do not run `prove_it init` or `reinit`.

**Worktree.** Work in a dedicated worktree before any planning or code; the main checkout is shared. Derive a kebab-case slug, ticket reference first (`app-1234-csv-export`). If already in a worktree under `.claude/worktrees/`, keep it. Otherwise call `EnterWorktree` with the slug. Then run `git branch -m feature/<slug>`. Never commit to `main` or `master`.

**Right repo.** Before planning, check that this repo holds the ticket: at least one of its Areas paths, or the parent folder of a new file, exists here. If not, stop and tell the user which repo the ticket belongs in. Never create a worktree in another repo with `git worktree add`. The session stays tied to the repo it started in, and a hand-made worktree can track the wrong remote branch.

**Stack setup** (stacked mode only):

```bash
trunk=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')
git fetch origin <parent>
git switch --no-track -C feature/<slug> origin/<parent>
git-spice repo init --trunk "$trunk" --remote origin
git-spice branch track <parent> --base "$trunk"
git-spice branch track feature/<slug> --base <parent>
git branch --unset-upstream 2>/dev/null || true
```

`--no-track` matters: a plain `-C` from `origin/<parent>` sets the branch's upstream to the parent's remote branch. git-spice pushes to a branch's upstream, so this ticket's commits would land on the parent's PR. The first `git-spice branch submit` creates `origin/feature/<slug>`. Do not use `git reset --hard`; a permission rule denies it.

Skip `branch track <parent>` if `git-spice log short` already lists it. If the parent is not on `origin`, or `git-spice auth status` fails, stop and tell the user.

Tracking does not link the parent's open PR, so the stack comment on this PR would not name it. If `git-spice log short` shows the parent without a `(#<n>)`, link it:

```bash
[ "$(git rev-parse <parent>)" = "$(git rev-parse origin/<parent>)" ] && git-spice branch submit --branch <parent> --no-prompt --force
```

With the SHAs equal this pushes nothing; `--force` only skips the "outdated branch" check when trunk has moved. If the SHAs differ, skip it and tell the user. Never push or restack another session's branch.

**Base branch.** In stacked mode, the parent. Otherwise the default branch from `git symbolic-ref --short refs/remotes/origin/HEAD`, or whichever of `origin/main` / `origin/master` exists.

**Link the prove_it files.** They are untracked, so a new worktree lacks them. Link them from the main checkout and keep them out of `git status`:

```bash
main=$(git worktree list --porcelain | head -1 | cut -d' ' -f2)
exclude="$(git rev-parse --git-common-dir)/info/exclude"
for f in script/test script/test_fast .claude/prove_it/config.json .claude/rules/testing.md .claude/rules/done.md; do
  if [ -e "$main/$f" ] && [ ! -e "$f" ]; then mkdir -p "$(dirname "$f")" && ln -s "$main/$f" "$f"; fi
  if ! git ls-files --error-unmatch "$f" >/dev/null 2>&1; then grep -qxF "/$f" "$exclude" || echo "/$f" >> "$exclude"; fi
done
```

If `script/test_fast` is missing or says "No tests configured", stop and tell the user. Never edit the linked files; edits write through to every worktree. Never make `script/test_fast` run the full suite; it runs on every stop and commit.

## Step 1: Start the ticket

If there is a ticket, assign it to me and move it to In Progress. If it has a `Planner:` line, run `ListAgents` and comment `Implementer: <name> [ref]` on the ticket.

## Step 2: Establish the specification

### 2a: Identify the input

It must be one of:

1. A ticket. Fetch it. Read the file or Linear document on its `TRD:` line, if any. A "Read first" block overrides the text below it.
2. A Linear document URL or a local path to a spec, TRD, or plan. For a TRD ticket, read the whole TRD.
3. A TRD or plan produced earlier in this session. Do not re-ask what is settled.
4. Prose that says what changes, where, and how you would know it worked.

Otherwise, stop and offer to write a spec first. Do not design one from an investigation. If the user explicitly asks to design in-session, run `superpowers:brainstorming` and use its output as the spec.

### 2b: Validate against the code

Check each assumption the spec makes about the existing system, including implicit ones, against the code, with `file:line`. Skip this for a trivial single-file change.

- **FALSE:** stop, in lane mode too, and give the user the evidence. Fixing the spec is their call.
- **Not settled by the code:** make it a verification task.

### 2c: Decompose

List tasks in dependency order, each with its files, the spec items it covers, and open questions. Mark tasks that are independent and share no files.

### 2d: Approval

Present the breakdown and any 2b corrections, and ask for explicit approval. Feedback is not approval. End with a ready-to-run `/rename <TICKET> <slug>`. In lane mode, post the breakdown and continue.

## Step 3: Prove statements

Write `.claude/prove_statements.md`: one falsifiable statement per significant behavior, each naming a command and its expected output, e.g. "`yarn test src/export.test.ts` exits 0 and reports 4 passed." Scope each command to its behavior, never the whole suite. Leave any broad command the user already wrote.

## Step 4: Failing tests

Write tests for each prove statement. Run only those files and confirm they fail because the feature is missing.

## Step 5: Implement

Work the tasks in order. For each: implement only what it needs, run its tests and lint, check the diff against its spec items, and commit.

Independent tasks may go to parallel `feature-implementer` dispatches in one message, each with its scope, spec items, and test and lint commands. Check each returned diff against its spec items yourself.

## Step 6: Prove

Dispatch `feature-prove-verifier` with the contents of `.claude/prove_statements.md`. On a failure, fix and re-dispatch.

## Step 7: Cold review

Dispatch `feature-adversarial-reviewer` with only `origin/<base>`, and no plan, spec, or intent. Fix every Critical and High finding, use judgment on Medium, and give a reason for any you reject. Test what you change.

## Step 8: Cleanup

Remove debug output, dev TODOs, and commented-out code this branch added. Lint `git diff --name-only origin/<base>...HEAD` and fix violations without ignore comments. Leave files this branch did not touch. Commit.

## Step 9: Draft PR

```
gh pr create --draft --title "<imperative title>" --body "<what changed, why, how to verify>"
```

In stacked mode, use `git-spice branch submit --draft --no-prompt --title ... --body ...` instead, and say in the body which PR it builds on. The body cites the prove statements and their evidence. Open the URL (`open` or `xdg-open`) and report it. Never run `gh pr ready`, `gh pr merge`, `--add-reviewer`, `--reviewer`, or `--no-draft`.

Step 10 uses the PR number from this command, never one found with `gh pr list`.

With a `Planner:` line, send `<ID> PR open: <url>` with the base branch. Do not run `/run-lanes`.

## Step 10: Automated review loop

Watch CI, mergeability, and automated review comments. Never wait for a human. Each poll runs both:

```
gh pr view <n> --json reviewDecision,comments,reviews,statusCheckRollup,mergeable,mergeStateStatus,baseRefName \
  --jq '{reviewDecision, mergeable, mergeStateStatus, baseRefName,
         comments:[.comments[]|{id, author:.author.login, at:.createdAt, body}],
         reviews:[.reviews[]|{author:.author.login, state, at:.submittedAt, body}],
         checks:[.statusCheckRollup[]?|{name:.name, status:.status, conclusion:.conclusion}]}'

gh api repos/{owner}/{repo}/pulls/<n>/comments --jq '.[]|{author:.user.login, path, line, body}'
```

Not `gh pr view --comments`; it truncates and skips inline comments. Bots post differently per repo, so read both and key on the newest body per author. `mergeable: UNKNOWN` is not a pass. `mergeStateStatus: DRAFT` is expected, and `BLOCKED` usually means something is pending, not a conflict.

On each poll, in order:

1. `CONFLICTING`, `DIRTY`, or `BEHIND`: rebase.
2. Failing check: fix, test, push.
3. Unaddressed review comments, bot or human: fix and push, or explain why not.
4. Several top-level comments from one bot: minimize all but the newest. Never touch a human's comment.

```
gh api graphql -f query='mutation($id: ID!) { minimizeComment(input: {subjectId: $id, classifier: OUTDATED}) { minimizedComment { isMinimized } } }' -f id="<comment id>"
```

### Rebasing

Rebase, never merge: `git fetch origin <baseRefName>` then `git rebase origin/<baseRefName>`. In stacked mode, run `git-spice repo sync`, `git-spice branch restack`, `git-spice branch submit --no-prompt` on every poll, since GitHub often misses a moved parent. Restack only this branch.

Keep both sides of a conflict and regenerate lockfiles. Then re-run the prove statement commands. Push with `--force-with-lease` (or `git-spice branch submit`), never `--force`. If the push is rejected, stop and tell the user. If a resolution needs intent you lack, abort the rebase (`git rebase --abort`, or `git-spice rebase abort`) and tell the user which files conflicted and what each side wanted.

### Cadence and exit

While anything is pending, `ScheduleWakeup` for 180 seconds. Stop when every check is `COMPLETED` without failure, `mergeable` is `MERGEABLE`, and every automated comment is addressed. Then post this, with no offers or questions:

> **Pipeline complete.** Draft PR: `<url>`
> - CI: `<n>` checks passed
> - Mergeable: yes
> - Automated review: `<addressed / none posted>`
> - `reviewDecision`: `<value, or "none yet">`
>
> Yours from here: request reviews, mark ready, merge.
