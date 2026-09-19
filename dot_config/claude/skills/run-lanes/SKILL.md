---
name: run-lanes
description: Starts one background /feature session per ticket in a TRD lane, each in its own worktree, so a set of parallel tickets launches with one command. Use when a TRD has a Lanes line and the user wants to start a lane, or runs /run-lanes.
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion
---

Start a lane of tickets from a TRD as background `/feature` sessions. $ARGUMENTS may hold a TRD path, a lane (e.g. `lane 2`), or ticket numbers (e.g. `1 2 3`).

This skill only launches sessions. It does not implement, monitor, or merge anything.

---

## Step 1: Find the TRD and the lane

Use the TRD path in $ARGUMENTS. Otherwise use the newest `docs/plans/*-trd.md` in the current repo, or in the sibling repos when you run from a parent directory. Read the whole TRD, including the `**Lanes:**` line and each ticket's `**Depends on:**`.

Pick the tickets:

- **Tickets or a lane named in $ARGUMENTS:** use those.
- **Nothing named:** take the first lane that has not started. When the tickets have tracker IDs, check their status to see which lanes are done.

**A lane can start only when every ticket it depends on is merged to the default branch.** New worktrees branch from the remote default branch, so an open PR is not enough. If a dependency is not merged, say which one and stop.

## Step 2: Resolve each ticket

For each ticket, work out:

- **Reference:** the tracker ID if the ticket has one (e.g. `APP-1234`). Otherwise `<absolute TRD path> ticket <N>`. Use an absolute path, because the session may run in another repo.
- **Repo:** the git repo that holds the ticket's **Areas**. From a parent directory with sibling repos, match by repo name. If any ticket is ambiguous, ask once for all of them.
- **Slug:** kebab-case, with the ticket reference first and at most 40 characters (e.g. `app-1234-export-endpoint`).

If you picked the lane yourself, list the tickets, repos, and slugs, and ask for one confirmation. If the user named the tickets, skip the confirmation.

## Step 3: Launch

Run one Bash call per ticket:

```bash
cd <repo> && command claude --bg -w <slug> -n "<REFERENCE> <slug>" --model sonnet --effort high "/feature <reference> --lane"
```

- `command` skips the user's `claude` shell wrapper, which only loads partly inside the Bash tool and would add a second set of model flags.

- `--bg` starts the session in the background and prints its short ID.
- `-w <slug>` gives the session its own worktree. `/feature` keeps it and renames the branch to `feature/<slug>`.
- `-n` names the session to match the branch, so the session list, branch, and PR line up.

The launch writes session state outside the repo. If the sandbox blocks it, retry the same call outside the sandbox. Record each printed ID. If one launch fails, keep launching the others and report the failure.

## Step 4: Report and stop

```
Lane started
  <REFERENCE>  <repo>  <session id>
  <REFERENCE>  <repo>  <session id>

  claude agents        list running sessions
  claude attach <id>   open one to answer a question or watch it
```

Each session stops to ask only when it hits a false spec assumption, a rebase it cannot resolve, or placeholder prove_it scripts. Otherwise it ends with a draft PR. When the lane's PRs are merged, run `/run-lanes` again for the next lane.
