# /run-lanes

Starts every ticket that is ready to build as its own background `/feature` session, with one command. Ready means the ticket has not started and everything it depends on is merged.

## Why

Serial work waits on blockers that are often small, like one API param. The fix is to decide interface shapes during planning, so most tickets depend only on the contract, not on each other's code. Then several tickets can be built at once. `/run-lanes` removes the chore of starting each of those sessions by hand.

## The workflow

1. **`/technical-plan`**, then **`/technical-requirements-document`** in the same session. The TRD pins every interface shape up front and orders the tickets:
   - **Ticket 0** lands the contract, for example an endpoint that returns a fixed response in the final shape, behind a feature flag.
   - Middle tickets depend on the **contract** only, so they run in parallel.
   - The **last ticket** swaps the fixed response for the real one and checks each consumer.
2. **Create the tickets** when the TRD skill offers. It adds "blocked by" links in Linear, copies the relevant contract text into each ticket, and writes the ticket IDs back into the TRD.
3. **`/run-lanes <TRD path or Linear project URL>`**. Usually this starts ticket 0 alone.
4. **Merge** the PRs that come back, and let the tickets reach Done.
5. **`/run-lanes` again.** Now the contract tickets are ready, and they all start at once. Repeat until nothing is left.

```
/run-lanes docs/plans/2026-09-18-csv-export-trd.md
/run-lanes https://linear.app/<workspace>/project/<project>
/run-lanes <project URL> APP-1235 APP-1236    # only these, if ready
```

## What to expect

- **The choice is a fixed rule.** It starts every ready ticket and nothing else. Running it twice in a row starts nothing new, because `/feature` moves each ticket to In Progress.
- **Each ticket gets its own background session.** Each one has its own worktree and a name that matches its branch, and runs `/feature <ID> --lane` at sonnet/high. Lane mode skips the plan approval wait, because the TRD ticket is already approved.
- **You get draft PRs back.** A session stops early only for a false spec assumption, a rebase conflict that needs your intent, or placeholder prove_it scripts. Use `claude agents` to see them, and `claude attach <id>` to answer.
- **The launch is the same every time, but the code is not.** Each session runs the same `/feature` pipeline. The model still writes the code, so two runs of one ticket do not produce identical diffs.

## Requirements

- The tickets exist in the tracker with IDs. A TRD without ticket IDs stops the run.
- Blockers are merged, not only open. New worktrees branch from the remote default branch.
- For tickets across several repos, run it from the parent folder that holds them.
