---
name: run-lanes
description: Starts one background /feature session for every ticket in a TRD's project that is ready to start, each in its own worktree, so parallel tickets launch with one command. Use after /technical-requirements-document has created tickets, when the user wants to start the next set of unblocked tickets, or runs /run-lanes.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, mcp__linear-server__get_project, mcp__linear-server__get_issue, mcp__linear-server__list_issues, mcp__linear-server__get_document, mcp__linear-server__get_attachment
---

Start every ready ticket from a TRD as a background `/feature` session. $ARGUMENTS is a TRD file path or a tracker project URL. It may also name ticket IDs, which limits the run to those tickets.

This skill only launches sessions. It does not implement, monitor, or merge anything.

---

## Step 1: Get the tickets

- **TRD file path:** read the TRD. Take the ticket IDs from its ticket headings. If the headings carry no IDs, the tickets were never created: stop and tell the user to create them from `/technical-requirements-document` first.
- **Project URL:** fetch the project and list its issues.

Fetch every ticket from the tracker, with its status, its blockers, and its attachments. Fetch each blocker too. Blockers are the ticket's "blocked by" relations, or the `Blocked by:` line at the top of its description. A `Start after: <condition>` line at the top of a description is a condition the tracker cannot check, for example "Start after: APP-4508 deployed to production".

## Step 2: Pick the ready tickets

Only a ticket whose status has not started (Backlog, Todo, or the tracker's equivalent) can be ready. For each one, work through 2a to 2d.

### 2a: Find each blocker's branch

A blocker has **work done in a branch** when it has an open PR, draft or not, or its status is In Review. Find its branch in this order, and stop at the first match:

1. An open PR whose head branch starts with `feature/<lowercase blocker ID>-`. `/feature` names branches that way.

   ```bash
   gh pr list --state open --json number,headRefName --jq '.[] | select(.headRefName | startswith("feature/<lowercase blocker ID>-"))'
   ```

2. A GitHub PR link in the blocker's tracker attachments. Use it only if `gh pr view <url> --json state,headRefName` says the PR is open.
3. An open PR that names the ID, with a head branch that contains `<lowercase blocker ID>-`:

   ```bash
   gh pr list --state open --search "<ID>" --json number,headRefName --jq '.[] | select(.headRefName | contains("<lowercase blocker ID>-"))'
   ```

If a step finds more than one PR, the branch is unknown. If the blocker is In Review and no step finds a branch, the ticket waits, and the report says "In Review, no open PR found".

**Blocker repo.** Take the blocker's repo from its Areas, or from the repo of its PR link. A ticket cannot stack on a branch in another repo. So a blocker in another repo counts only when it is Done. Until then, the ticket waits, and the report names that repo.

### 2b: Reduce the blockers

1. Drop every blocker that is Done.
2. Drop every remaining blocker that is an ancestor of another remaining blocker. Blocker A is an ancestor of blocker B when either is true:
   - **Tracker:** A blocks B, directly or through a chain of other tickets.
   - **Git:** both have branches, and A's branch is in B's history:

     ```bash
     git fetch origin
     git merge-base --is-ancestor origin/<A branch> origin/<B branch>
     ```

   B's branch already holds A's work, so A adds no new wait.

### 2c: Apply the rule

1. **Ready on trunk:** no blockers remain.
2. **Ready to stack:** exactly one blocker remains, it is in the ticket's repo, and 2a found its branch. That branch is the parent.
3. **Waits:** anything else. Two or more unrelated blockers remain, because a git-spice branch has only one parent. Or the one remaining blocker has no branch yet, or is in another repo.

### 2d: Confirm `Start after:` conditions

Never treat a `Start after:` condition as met on your own. If a ticket passes 2c and has one, list it under "Needs confirmation". Ask the user about all of them in one `AskUserQuestion` call per run, one option per ticket. Start only the ones the user confirms. A ticket that does not pass 2c waits as usual, whatever its condition says.

### Start the ready tickets

Start every ready ticket, and only those. If $ARGUMENTS names IDs, start only the named IDs that are ready. Apply these rules exactly; do not skip, add, or reorder tickets by judgment. `/feature` moves each ticket to In Progress, so a second run never starts a ticket twice.

If nothing is ready, report each open ticket with what it waits on, and stop.

## Step 3: Resolve each ticket

- **Repo:** the git repo that holds the ticket's Areas. From a parent directory with sibling repos, match by repo name. If this session runs in a worktree, use the main checkout (the first path in `git worktree list --porcelain`) and look for sibling repos next to it. If any ticket is ambiguous, ask once for all of them.
- **Slug:** kebab-case, the lowercase ID first, at most 40 characters (e.g. `app-1234-export-endpoint`).
- **git-spice login:** if any ticket is ready to stack, run `git-spice auth status` in its repo. If it fails, do not launch the stacked tickets. Tell the user to run `! git-spice auth login` and pick the GitHub CLI method, then run `/run-lanes` again. Still launch the tickets that are ready on trunk.

## Step 4: Launch

Run one Bash call per ticket:

```bash
cd <repo> && command claude --bg -w <slug> -n "<ID> <slug>" --model sonnet --effort high "/feature <ID> --lane"
```

- `command` skips the user's `claude` shell wrapper, which only loads partly inside the Bash tool and would add a second set of model flags.
- `--bg` starts the session in the background and prints its short ID.
- `-w <slug>` gives the session its own worktree. `/feature` keeps it and renames the branch to `feature/<slug>`.
- `-n` names the session to match the branch.

For a ticket that is ready to stack, append `--stack-on <parent branch>` to the prompt, for example `"/feature <ID> --lane --stack-on feature/app-1234-export-endpoint"`. `/feature` moves the worktree onto the parent and opens its PR against the parent branch.

The launch writes session state outside the repo. If the sandbox blocks it, retry the same call outside the sandbox. If one launch fails, keep launching the others and report the failure.

## Step 5: Report and stop

```
Started
  <ID>  <repo>  <session id>
  <ID>  <repo>  <session id>  stacked on <parent branch>

Needs confirmation
  <ID>  Start after: <condition>

Waiting
  <ID>  blocked by <IDs>: <reason, e.g. "two unrelated blockers", "APP-1230 has no branch yet", "APP-1230 In Review, no open PR found", "APP-1230 is in <repo>, waits for Done">

  claude agents        list running sessions
  claude attach <id>   open one to answer a question or watch it
```

Each session ends with a draft PR, or stops to ask when it finds a false spec assumption, a rebase it cannot resolve, or placeholder prove_it scripts. Run `/run-lanes` again when a PR opens or merges, to start what it unblocked. When the tickets have a `Planner:` line, each session messages the planner when its PR opens, and the planner offers to run `/run-lanes`. After a parent PR merges, a stacked session that already finished does not move itself onto trunk. The user runs `git-spice repo sync --restack` and `git-spice stack submit` for that.
