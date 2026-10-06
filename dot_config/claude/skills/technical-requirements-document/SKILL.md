---
name: technical-requirements-document
description: Writes a detailed technical requirements document (TRD) with a ticket-by-ticket breakdown, normally run straight after /technical-plan in the same session so it can build on the approach and decisions already established. Use when a technical plan needs to become implementable specs, when someone asks for a TRD or detailed technical requirements, or when work needs breaking into tickets that separate sessions will pick up.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebFetch, AskUserQuestion, Task, ListAgents, SendMessage, mcp__linear-server__save_comment, mcp__linear-server__list_comments, mcp__linear-server__get_project, mcp__linear-server__get_issue, mcp__linear-server__list_issues, mcp__linear-server__get_document, mcp__linear-server__save_issue, mcp__linear-server__save_document, mcp__linear-server__list_teams, mcp__linear-server__list_projects
---

Write a technical requirements document for the work in $ARGUMENTS, or for the work already established in this session.

Act as a **staff engineer writing the spec someone else will build from**. Every requirement should be specific enough to implement and binary enough to verify.

---

## Step 0: Establish the input

**If a technical plan was produced earlier in this session, use it and the conversation around it.** That is the intended path: this skill runs second, and the approach, the decisions, the alternatives already rejected, and the code you traced are all still in context. Do not re-derive them, and do not re-ask the user anything already settled. Re-litigating decided questions is the main failure mode of this skill.

Otherwise, locate the plan from $ARGUMENTS: fetch a Linear document, project, or issue link with the Linear tools, and read a local path if the user gave one. For a project, look for a technical plan among its documents. If there is no plan and no brief, say so and ask for one rather than inventing an approach; producing a TRD on top of an unstated approach buries the design decision inside implementation detail where nobody will review it.

Fill gaps from the code, not from assumption. Where the plan left something open, either resolve it by reading the code and say so, or carry it into Open Questions with an owner.

---

## Step 1: Write the TRD

Write a working draft. The draft is only for editing. Once published (Step 2), the Linear document is the TRD of record, and every reference to the TRD uses its URL.

- **Work project with a vault folder:** write to `Plans/YYYY-MM-DD <Name> TRD.md` in that folder. Find the folder from the session-start context, or with `claude-vault-context --find <Linear project ID>`. The vault is outside the sandbox write list, so vault writes need the sandbox off.
- **Otherwise:** write to `docs/plans/YYYY-MM-DD-<slugified-name>-trd.md`, or to `$TMPDIR` if this session cannot write to the shared checkout.

**Never write a local filesystem path into the tracker.** No absolute or home-relative path in a ticket, comment, or document. It exposes the user's machine and means nothing to anyone else. Repo-relative code paths, such as `app/models/user.rb`, are fine.

This session becomes the planner: the session that implementers ask about the spec (see "Act as the planner" below). `ListAgents` gives its name and ref on the first line.

- **With a vault folder:** session names stay out of Linear. Set `planner-session:` in the vault main file to the name from `ListAgents`, and drop the **Planner session** line from the TRD.
- **Otherwise:** fill in **Planner session** from `ListAgents`.

```markdown
# TRD: <Name>

**Date:** YYYY-MM-DD
**Status:** Draft
**Technical plan:** <Linear document URL, or "none">
**Planner session:** <name> [ref]

---

## Scope

<2 to 3 sentences on what this document covers, and one line on what it deliberately leaves to a later phase.>

## Data and Storage Changes

<Tables, columns, types, nullability, indexes, defaults, and backfill needs. Omit the section entirely if nothing changes; do not write "N/A" sections.>

## Interfaces and Contracts

<Endpoints, function or module signatures, events, payload shapes, error shapes. Anything another piece of code calls. Mark each as new, changed, or unchanged-but-relevant. For a change, state what breaks and who consumes it.

This section is the contract that lets tickets run in parallel, so pin it completely: every param, field, type, nullability, and error shape. A detail left for the implementer to decide turns one ticket into a blocker for every ticket that consumes it.>

## Behavior

<The rules. Include the edge cases and failure paths explicitly, because those are where implementations diverge: empty states, concurrent access, partial failure, permission boundaries, and what happens on invalid input.>

## Ticket Breakdown

<The section the rest of the document exists to support. One subsection per ticket, ordered so dependencies come first. See "Contract-first tickets" below for ticket 0, the stub swap, and lanes.>

**Lanes:** <one line per lane: which tickets can start at the same time, e.g. "After ticket 0: 1, 2, 3". Omit when every ticket is serial.>

### <N>. <Ticket title>

**What:** <2 to 3 sentences. What changes and why, written for someone who has not read the rest of this document.>
**Areas:** <paths or modules touched>
**Depends on:** <"contract (ticket 0)", "implementation (ticket N)", or "nothing">
**Size:** <S / M / L>

**Acceptance criteria**

- [ ] <Binary, verifiable condition. Passes or fails with no judgment.>
- [ ] <Another>

## Test Strategy

<What gets tested at which level, and what specifically must be covered because it is easy to get wrong. Not a restatement of the acceptance criteria.>

## Rollout

<Feature flags, migration order, backfill, and what a rollback looks like. Omit the section if the change ships in one piece with no migration.>

## Open Questions

<Anything still undecided. Omit the section if there is nothing genuinely open; do not manufacture questions to fill it.>

| Question | Why it matters | Owner |
|---|---|---|
```

---

## The rule that governs this document

**Every ticket must be implementable by a session that has never seen this conversation.**

That is not a style preference, it is the operating constraint. Tickets get picked up in separate, short-lived sessions that start cold with only the ticket text and the codebase. A step that is obvious given the discussion behind this document is not obvious to them.

Use it as the editing rule in both directions. Anything a cold implementer would need and cannot infer must be written down. Anything that does not help one is padding: the request restated, a summary of the document, a conclusion, a section marked "N/A", or an explanation of a decision that is already made and no longer actionable.

Concretely, a ticket is not ready if it uses a term defined only in conversation, says "as discussed" or "per the plan", says "update the relevant tests" without saying which behavior, or has acceptance criteria requiring judgment to evaluate.

---

## Contract-first tickets

Decide interface shapes here, in planning, not during implementation. A backend ticket that blocks frontend work only to add one param is a planning gap, not a real dependency.

Apply this whenever tickets meet across a boundary: backend and frontend, service and consumer, or two repos.

**Ticket 0: land the contract.** The smallest mergeable change that makes the interface real, with no business logic. For example, the endpoint or param exists, accepts the pinned request shape, and returns a fixed response in the pinned shape. Put it behind the work's feature flag. Consumers build against it while the real implementation happens in parallel. Skip ticket 0 when consumers can build and test from the written contract alone, for example with mocks, and have their tickets depend on the Interfaces section instead.

**Split every dependency into one of two kinds.** `contract (ticket 0)` means the ticket needs only the shape, so it starts as soon as ticket 0 has an open PR, stacked on ticket 0's branch. `implementation (ticket N)` means it needs working behavior, so it starts as soon as ticket N has an open PR, stacked on ticket N's branch. Neither kind waits for a merge. Default to `contract`. Use `implementation` only when the ticket truly cannot be built or tested without the real behavior, and say why in its What.

**Last ticket: swap the stub.** When ticket 0 shipped a fixed response, end with a ticket that depends on the implementation tickets. It removes the fixed response, confirms each consumer works against the real behavior, and lists each consumer to check in its acceptance criteria. Integration surprises land here, in one visible ticket, instead of scattered across the others.

**Group tickets into lanes.** A lane is a set of tickets whose dependencies are all met at the same point, so they can run in separate sessions at the same time. List the lanes above the tickets.

**List direct dependencies only.** If ticket 3 needs ticket 2, and ticket 2 needs ticket 1, ticket 3 depends on ticket 2 alone. A redundant dependency becomes a redundant blocker in the tracker, and `/run-lanes` can make a ticket wait for it.

---

## Step 2: Print a summary

```
TRD written
  Work:      <name>
  Draft:     <working draft path>
  Tickets:   <count>
  Lanes:     <e.g. "0 → 1, 2, 3 → 4", or "serial">
  Open Qs:   <count>

Next steps:
  /run-lanes <TRD document URL>   after creating tickets, start every ready ticket in the background
  /feature <ticket>   implement one ticket, TDD pipeline
  build <ticket>      implement one ticket in a fresh session
```

Then offer to publish the TRD and create the tickets in the tracker, and **wait for explicit confirmation before creating or editing anything.** Creating issues and documents is visible to other people and tedious to undo, so never do it as a side effect of writing the document.

### Publish the TRD

When confirmed, first publish the TRD as a Linear document on the project with `mcp__linear-server__save_document`, so the tickets can link to it.

### Create new tickets

Then create the tickets in dependency order, in the same project, and report the created identifiers. Each ticket must work for a cold session that only reads the ticket, so its description holds:

- The What, Areas, and acceptance criteria.
- The Interfaces and Contracts entries it produces or consumes, copied verbatim.
- `TRD: <Linear document URL>`
- `Planner: <name> [ref]`, from the TRD header. Only without a vault folder.

Record each **direct** dependency as a "blocked by" relation to the blocking ticket, using the tracker's relation fields. Never add a transitive one: if 3 needs 2 and 2 needs 1, ticket 3 is blocked by 2 only. Redundant blockers make `/run-lanes` wait. If the tracker cannot set relations, start the description with `Blocked by: <IDs>` instead. `/run-lanes` reads these to decide what can start.

If a ticket must wait for something the tracker cannot express, such as a deploy, start its description with `Start after: <condition>`, for example "Start after: APP-4508 deployed to production". `/run-lanes` asks the user before it starts that ticket.

### Adopt existing tickets

If the work already has tickets, do not create duplicates. Match each TRD ticket to its existing ticket, and create only the TRD tickets with no match. For each existing ticket:

- Add a "Read first" block at the top of its description, below any `Blocked by:` or `Start after:` line. Keep the old text below it.

  ```markdown
  **Read first. This block supersedes the text below.**
  TRD: <Linear document URL>
  Planner: <name> [ref]
  - <each correction, e.g. "The endpoint is /exports, not /reports/export.">
  ```

  Leave out the `Planner:` line when there is a vault folder.

- Add any missing direct "blocked by" relations. Remove none without asking.

### Write back

Write the identifiers back into the Linear document and the draft: in each ticket heading (`### 2. APP-1234: <title>`), in each Depends on line, and in the Lanes line. The TRD and the tracker must name the same tickets. If you edit the TRD later, update the Linear document first.

With a vault folder, also:
- Add every created and adopted ticket ID to `tickets:` in the vault main file. Keep the inline list form, for example `tickets: [APP-101, APP-102]`. The session-start hook finds the project by this list.
- Add `status: published` and `linear-url: <TRD document URL>` to the draft's frontmatter. From then on the draft is a frozen snapshot. Make later TRD edits in Linear.

### Act as the planner

After the tickets exist, stay in this session as the planner. Lane sessions message you here with `SendMessage`. Reply to the `from` name on each message.

- **Spec questions:** answer from the TRD, the plan, and the code. If the answer changes or adds to the spec, update the TRD, the Linear document, and the ticket's "Read first" block before you reply, so later sessions get it too. If the question needs a decision the user has not made, ask the user, then relay the answer.
- **`<ID> PR open: <url>`:** tell the user, and ask whether to run `/run-lanes <TRD document URL>` now. Run it only when the user says so.
- **Reaching an implementer:** with a vault folder, each lane session adds a line with its name under `## Sessions` in the vault main file. Otherwise, it comments `Implementer: <name> [ref]` on its ticket. Use that name to send a correction or a question down to it.

---

## Writing principles

**Specific over short, here.** This is the opposite of the technical plan's bias. A vague TRD costs an implementation session to discover; a long one costs a few minutes of reading. When the two conflict, choose specific.

**Acceptance criteria are conditions, not descriptions.** "Supports filtering" describes. "Given a filter matching zero rows, the response is 200 with an empty array and no error" is a condition.

**Size tickets by what one session can finish.** A ticket too large to complete in one sitting will be split by whoever picks it up, and they will split it worse than you would, without the context you have right now.

**Omit empty sections rather than marking them N/A.** A section header with nothing under it costs the reader attention and returns nothing.
