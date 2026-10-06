---
name: end-task
description: Closes out a finished ticket session. Writes a task note to the work project's vault folder with what was built and evidence-backed highlights of my contribution, then removes the worktree and local branch. Use when a ticket's PR has merged, when the user is done with a ticket session, or runs /end-task.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ExitWorktree, mcp__linear-server__get_issue, mcp__linear-server__list_comments
---

Close out the ticket in $ARGUMENTS, or the ticket this session worked on.

Act as a **supportive manager writing up my part in this ticket**. Find the moments I would forget or undersell: ownership, work beyond the ticket, decisions I drove, problems I caught, help I gave. Be honest. Every claim needs evidence, and nothing gets inflated.

## Where things live

- Vault: `~/Syncthing/ObsidianWork`. The project folder is `1_Projects/<Name>/`, with the main file `<Name>.md` and task notes in `Tasks/`.
- The vault is outside the sandbox write list, so vault writes need the sandbox off.
- `claude-vault-context --find <ticket ID>` prints the project folder, or exits 1.

## Step 1: Find the ticket and project

The ticket ID comes from $ARGUMENTS, else the branch name (`feature/app-1234-slug` is `APP-1234`), else the session-start context. If none, ask.

Find the project with `claude-vault-context --find <ID>`. If none matches, ask which project folder to use, or whether to stop. If I pick one, add the ID to its `tickets:` list.

## Step 2: Check the PR

Find the PR for this branch with `gh pr view --json number,url,state,mergedAt,title,body`. If it is not merged, say so and ask whether to continue. The task note is written either way. Cleanup waits for my answer.

## Step 3: Gather evidence

- This session's history: what I asked for, decisions I made, pushback I gave, problems I spotted.
- PR commits, description, review threads (`gh api repos/{owner}/{repo}/pulls/<n>/comments` and `gh pr view <n> --json reviews,comments`), and CI results.
- The Linear ticket and its comments.

Early parts of a long session may be lost to compaction. Lean on the PR and review record for those.

## Step 4: Write the task note

Write `1_Projects/<Name>/Tasks/<ID>.md`. If it exists, show me the difference and ask before replacing it.

```markdown
---
ticket: <ID>
pr: <url>
merged: <YYYY-MM-DD, or "not merged">
---

# <ID>: <ticket title>

**Ticket:** <Linear URL>
**PR:** <url>

## Summary

<2 to 4 sentences: what changed, why it mattered, and to whom.>

## Highlights

- **<short label>:** <what I did and why it mattered>. Evidence: <commit SHA, review comment link, test name, or the session moment in one line>.

## Resume bullet

<One line, in the form "Did X, which led to Y", only if a highlight earns it. Otherwise "None for this ticket.">

## Loose ends

- <follow-ups or tech debt seen but not done, or omit the section>
```

Rules for highlights:
- No evidence, no highlight.
- Doing the ticket as written is the baseline, not a highlight.
- Name the specific thing. "Caught a race in the export job during review" beats "showed attention to detail".
- Zero highlights is a valid result. Say so plainly.

## Step 5: Update the main file

In `1_Projects/<Name>/<Name>.md`:
- Find the `## Sessions` line for this ticket and add ` · done YYYY-MM-DD · [[Tasks/<ID>]]`. If there is no line, add `- YYYY-MM-DD · <ID> · <session name> · done YYYY-MM-DD · [[Tasks/<ID>]]`.
- Set `last-touched` to today.

Edit the file in place. Keep everything else.

## Step 6: Clean up

Only after Steps 4 and 5 succeed, and only with a merged PR or my go-ahead:

1. Check `git status`. If there are uncommitted changes, list them and ask before you continue.
2. Note the branch name, then leave and remove the worktree with `ExitWorktree` (action `remove`). If this session did not create the worktree, give me the `git worktree remove <path>` command instead.
3. Delete the local branch with `git branch -D <branch>`. Leave the remote branch alone.

If any cleanup step fails, report it with the command to run by hand. The task note is already saved.

## Step 7: Report

```
Task closed
  Ticket:      <ID>
  Note:        1_Projects/<Name>/Tasks/<ID>.md
  Highlights:  <count>
  Cleanup:     <done, or what is left to do>
```
