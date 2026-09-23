---
name: run-lanes
description: Starts one background /feature session for every ticket in a TRD's project that is ready to start, each in its own worktree, so parallel tickets launch with one command. Use after /technical-requirements-document has created tickets, when the user wants to start the next set of unblocked tickets, or runs /run-lanes.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, mcp__linear-server__get_project, mcp__linear-server__get_issue, mcp__linear-server__list_issues, mcp__linear-server__get_document
---

Start every ready ticket from a TRD as a background `/feature` session. $ARGUMENTS is a TRD file path or a tracker project URL. It may also name ticket IDs, which limits the run to those tickets.

This skill only launches sessions. It does not implement, monitor, or merge anything.

---

## Step 1: Get the tickets

- **TRD file path:** read the TRD. Take the ticket IDs from its ticket headings. If the headings carry no IDs, the tickets were never created: stop and tell the user to create them from `/technical-requirements-document` first.
- **Project URL:** fetch the project and list its issues.

Fetch every ticket from the tracker, with its status and its blockers. Blockers are the ticket's "blocked by" relations, or the `Blocked by:` line at the top of its description.

## Step 2: Pick the ready tickets

A ticket is **ready** when its status has not started (Backlog, Todo, or the tracker's equivalent), and one of these is true:

1. **Ready on trunk:** every blocker's status is Done.
2. **Ready to stack:** exactly one blocker is not Done, and that blocker has an open PR in the ticket's repo. Find the PR by branch name, since `/feature` names branches `feature/<lowercase ID>-...`:

   ```bash
   gh pr list --state open --json number,headRefName --jq '.[] | select(.headRefName | startswith("feature/<lowercase blocker ID>-"))'
   ```

   Its `headRefName` is the parent branch. If the search finds no PR, or more than one, the ticket waits.

Start every ready ticket, and only those. If $ARGUMENTS names IDs, start only the named IDs that are ready. Apply this rule exactly; do not skip, add, or reorder tickets by judgment. `/feature` moves each ticket to In Progress, so a second run never starts a ticket twice.

A ticket with two or more blockers not Done waits, because a git-spice branch has only one parent. A blocker that is not Done and has no open PR is still being built, so its dependents wait for the next run.

If nothing is ready, report each open ticket with what it waits on, and stop.

## Step 3: Resolve each ticket

- **Repo:** the git repo that holds the ticket's Areas. From a parent directory with sibling repos, match by repo name. If any ticket is ambiguous, ask once for all of them.
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

Waiting
  <ID>  blocked by <IDs not yet Done>

  claude agents        list running sessions
  claude attach <id>   open one to answer a question or watch it
```

Each session ends with a draft PR, or stops to ask when it finds a false spec assumption, a rebase it cannot resolve, or placeholder prove_it scripts. Run `/run-lanes` again when a PR opens or merges, to start what it unblocked. After a parent PR merges, a stacked session that already finished does not move itself onto trunk. The user runs `git-spice repo sync --restack` and `git-spice stack submit` for that.
