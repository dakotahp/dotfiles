---
name: technical-requirements-document
description: Writes a detailed technical requirements document (TRD) with a ticket-by-ticket breakdown, normally run straight after /technical-plan in the same session so it can build on the approach and decisions already established. Use when a technical plan needs to become implementable specs, when someone asks for a TRD or detailed technical requirements, or when work needs breaking into tickets that separate sessions will pick up.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebFetch, AskUserQuestion, Task, mcp__linear-server__get_project, mcp__linear-server__get_issue, mcp__linear-server__list_issues, mcp__linear-server__get_document, mcp__linear-server__save_issue, mcp__linear-server__list_teams, mcp__linear-server__list_projects
---

Write a technical requirements document for the work in $ARGUMENTS, or for the work already established in this session.

Act as a **staff engineer writing the spec someone else will build from**. Every requirement should be specific enough to implement and binary enough to verify.

---

## Step 0: Establish the input

**If a technical plan was produced earlier in this session, use it and the conversation around it.** That is the intended path: this skill runs second, and the approach, the decisions, the alternatives already rejected, and the code you traced are all still in context. Do not re-derive them, and do not re-ask the user anything already settled. Re-litigating decided questions is the main failure mode of this skill.

Otherwise, locate the plan: read the path in $ARGUMENTS, look for a recent file in `docs/plans/`, or fetch the Linear project or issue. If there is no plan and no brief, say so and ask for one rather than inventing an approach; producing a TRD on top of an unstated approach buries the design decision inside implementation detail where nobody will review it.

Fill gaps from the code, not from assumption. Where the plan left something open, either resolve it by reading the code and say so, or carry it into Open Questions with an owner.

---

## Step 1: Write the TRD

Save to `docs/plans/YYYY-MM-DD-<slugified-name>-trd.md`.

```markdown
# TRD: <Name>

**Date:** YYYY-MM-DD
**Status:** Draft
**Technical plan:** <relative path, or "none">

---

## Scope

<2 to 3 sentences on what this document covers, and one line on what it deliberately leaves to a later phase.>

## Data and Storage Changes

<Tables, columns, types, nullability, indexes, defaults, and backfill needs. Omit the section entirely if nothing changes; do not write "N/A" sections.>

## Interfaces and Contracts

<Endpoints, function or module signatures, events, payload shapes, error shapes. Anything another piece of code calls. Mark each as new, changed, or unchanged-but-relevant. For a change, state what breaks and who consumes it.>

## Behavior

<The rules. Include the edge cases and failure paths explicitly, because those are where implementations diverge: empty states, concurrent access, partial failure, permission boundaries, and what happens on invalid input.>

## Ticket Breakdown

<The section the rest of the document exists to support. One subsection per ticket, ordered so dependencies come first.>

### <N>. <Ticket title>

**What:** <2 to 3 sentences. What changes and why, written for someone who has not read the rest of this document.>
**Areas:** <paths or modules touched>
**Depends on:** <ticket numbers, or "nothing">
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

## Step 2: Print a summary

```
TRD written
  Work:      <name>
  Saved to:  <file path>
  Tickets:   <count>
  Open Qs:   <count>

Next steps:
  /feature <ticket>   implement one ticket, TDD pipeline
  build <ticket>      implement one ticket in a fresh session
```

Then offer to create the tickets in the tracker, and **wait for explicit confirmation before creating anything.** Creating issues is visible to other people and tedious to undo, so never do it as a side effect of writing the document. When confirmed, create them in dependency order, put the ticket's What and acceptance criteria in the description, and report the created identifiers.

---

## Writing principles

**Specific over short, here.** This is the opposite of the technical plan's bias. A vague TRD costs an implementation session to discover; a long one costs a few minutes of reading. When the two conflict, choose specific.

**Acceptance criteria are conditions, not descriptions.** "Supports filtering" describes. "Given a filter matching zero rows, the response is 200 with an empty array and no error" is a condition.

**Size tickets by what one session can finish.** A ticket too large to complete in one sitting will be split by whoever picks it up, and they will split it worse than you would, without the context you have right now.

**Omit empty sections rather than marking them N/A.** A section header with nothing under it costs the reader attention and returns nothing.
