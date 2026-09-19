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

A ticket is **ready** when both are true:

1. Its status has not started (Backlog, Todo, or the tracker's equivalent).
2. Every blocker's status is Done.

Start every ready ticket, and only those. If $ARGUMENTS names IDs, start only the named IDs that are ready. Apply this rule exactly; do not skip, add, or reorder tickets by judgment. `/feature` moves each ticket to In Progress, so a second run never starts a ticket twice.

Done means merged. New worktrees branch from the remote default branch, so a blocker with an open PR is not done, and its dependents wait.

If nothing is ready, report each open ticket with what it waits on, and stop.

## Step 3: Resolve each ticket

- **Repo:** the git repo that holds the ticket's Areas. From a parent directory with sibling repos, match by repo name. If any ticket is ambiguous, ask once for all of them.
- **Slug:** kebab-case, the lowercase ID first, at most 40 characters (e.g. `app-1234-export-endpoint`).

## Step 4: Launch

Run one Bash call per ticket:

```bash
cd <repo> && command claude --bg -w <slug> -n "<ID> <slug>" --model sonnet --effort high "/feature <ID> --lane"
```

- `command` skips the user's `claude` shell wrapper, which only loads partly inside the Bash tool and would add a second set of model flags.
- `--bg` starts the session in the background and prints its short ID.
- `-w <slug>` gives the session its own worktree. `/feature` keeps it and renames the branch to `feature/<slug>`.
- `-n` names the session to match the branch.

The launch writes session state outside the repo. If the sandbox blocks it, retry the same call outside the sandbox. If one launch fails, keep launching the others and report the failure.

## Step 5: Report and stop

```
Started
  <ID>  <repo>  <session id>

Waiting
  <ID>  blocked by <IDs not yet Done>

  claude agents        list running sessions
  claude attach <id>   open one to answer a question or watch it
```

Each session ends with a draft PR, or stops to ask when it finds a false spec assumption, a rebase it cannot resolve, or placeholder prove_it scripts. When PRs merge and their tickets reach Done, run `/run-lanes` again to start what they unblocked.
