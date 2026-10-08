---
name: explain-project-deck
description: Use when the user needs to understand a project at a high level before signing off on it, when a plan, TRD or ticket set is too long to absorb quickly, when the user asks for a project briefing, overview deck or presentation, or runs /explain-project-deck.
---

# Explain a project as a briefing deck

Build a short slide deck that lets me understand a project well enough to sign off on it in one sitting. The deck is a snapshot taken at sign-off. It is not kept up to date as work progresses.

The level of detail is the point. A slide earns its place by answering a question I would otherwise dig through the plan or TRD to answer. Names of things, params, file paths and per-ticket detail stay out, except where a rule below lets them in.

## Step 1: Gather the project

Read, in this order, whatever exists:

1. The work project's vault main file (`claude-vault-context --find <Linear project ID>`): brief, decisions, open questions.
2. The technical plan and TRD (Linear documents on the project).
3. The Linear project description: the original request.
4. The code in the area the project touches. Slides 5 and 6 need the real classes and the request paths through them, so trace them in the repo; never draw them from the plan alone.

If no plan exists yet, stop and say the deck needs a plan first.

## Step 2: Write the deck to this contract

Fourteen slides, in this order. Each slide answers exactly one question.

| # | Question it answers | Content |
|---|---|---|
| 1 | What is this, in one breath? | Project name, a one-sentence pitch, 3–4 headline numbers (endpoints, tickets, waves, customers) |
| 2 | Why are we doing it? | Who asked, what they cannot do today, why it matters to the business |
| 3 | What will the user do? | The user's journey as 3–5 steps in their words, each marked "exists today" or "new" |
| 4 | What changes? | Then vs now table: capability or behavior, before, after |
| 5 | How does it work today? | Architecture of the area as it is before this project (see Step 3) |
| 6 | How will it work? | The same diagram after the project (see Step 3) |
| 7 | What are we reusing on purpose? | Where the new work calls existing logic, and why copying it would be dangerous |
| 8 | Which calls could have gone another way? | 3–5 key decisions: decision, chose, instead of, because |
| 9 | Where can this hurt us? | The risky areas, each with what goes wrong and its guard |
| 10 | What are we deliberately not doing? | Out of scope, including things a reader would assume are included |
| 11 | In what order does it get built? | Waves of work and the critical path, with no statuses |
| 12 | How does it ship and how do we undo it? | Numbered rollout steps, then one undo step |
| 13 | What do you need to decide? | Open questions: question, why it matters, owner |
| 14 | Are you ready to sign off? | 4–5 questions I should now answer without notes, each with a hidden answer I can reveal |

Rules for every slide:

- The title is the answer, written as a full sentence. "Customers can create surveys by API; today they can only read them", not "Background".
- One idea per slide: one diagram, one table, or up to five short points.
- Name things by role, in plain words ("the shared create step"). Code names appear only on slides 5 and 6.
- Numbers are welcome. Identifiers, params and file paths are not.
- Change types use the same four colors everywhere: new, changed, reused unchanged, removed.
- Every visual mark has a legend entry: colors, outlines, numbers, dashed borders, fading.

Slide 11 shows the plan's shape, not progress. It has no statuses, no "as of" date and no merged counts. For a project with complex sequencing, link a separate live sequencing page that is updated as PRs merge (see the vault note "Sequencing Page Design Method").

## Step 3: Draw the architecture pair

Slides 5 and 6 share one fixed layout, so the difference between them is visible at a glance.

- Lay the area out in rows: callers, endpoints, access rules, logic, data, external systems.
- Each box shows its role in plain words, with its class name in small print underneath.
- Every box keeps the same position on both slides. A box that exists only after the project is absent from slide 5; leave its space empty.
- Slide 5 draws everything as existing. Logic that lives inside a controller (or another place it does not belong) gets a dashed border, with that location in place of a class name.
- Slide 6 colors each box new, changed or reused. A box's note says what changed.
- Each slide traces at least one request: numbered badges on the boxes it passes through, in order, with a matching numbered list below titled "Traced request: <request>". Faded boxes are not part of that request. Slide 6 lets me switch between 2–4 traces, and one of them retraces slide 5's request after the change, to show reuse.

## Step 4: Build and publish

- Load `artifact-design` before writing. The deck is HTML: stacked 16:9 slides with a sticky pager, arrow-key navigation, and a single-column layout on phones. If the project already has a live sequencing page, reuse its fonts and colors so the two read as a set.
- Write the source to the vault project's `Artifacts/` folder as `<slug>-briefing.html`. The scratch copy is deleted with the session.
- Publish it as an Artifact titled "<Project name> Briefing". Statuses never go into it, so it needs no `db` capability.

## Step 5: Check before handing it over

- Each title is a sentence that answers its slide's question.
- No slide shows a status, date-stamped progress, file path or param list.
- Slides 5 and 6 put every box in the same place, and every mark is in a legend.
- Every fact about the existing system was confirmed in the code.

Then give me the link, and ask which slides I would cut, merge or expand.
