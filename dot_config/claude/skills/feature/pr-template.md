# PR Template

Use this file for every PR the feature skill opens. It overrides any PR template in the repo.

## Title

```
[TICKET-ID] Imperative summary
```

- The ticket ID always comes first, in square brackets, in upper case: `[APP-1234]`.
- After the ID, write a short imperative summary: `[APP-1234] Add CSV export to reports`.
- With no ticket, leave out the brackets. Do not invent an ID.

## Body

Write for a reviewer who knows the repo but has no context on this project or ticket. Use these four headings, in this order.

```markdown
## Overview

## Technical Approach

## How to Verify

## Ticket
```

Do not list test results, test commands, or other proof that the work was done. CI already runs the tests.

### Overview

Say what the change does and why, in plain words.

- Start with one or two sentences. For a small change, stop there.
- Add one short paragraph only when the reviewer needs more to make sense of the change. Two common cases:
  - The code is not used yet. Say what later work will use it for.
  - The change makes sense only with some backstory. Give the least backstory that makes it clear.
- No code identifiers here. Describe behavior, not names.

Small change:

> Adds the move-in date to the unit detail API response, so the app can show it without a second request.

Change that needs a second paragraph:

> Adds a calculator that estimates a renewal offer from a unit's rent history.
>
> Nothing calls it yet. A later ticket uses it to prefill the renewal form, so this PR only adds the calculator and its tests.

### Technical Approach

Explain how the change works, at the level of the design first.

- Open with one or two sentences that give the shape of the solution in plain words. A reviewer should understand the approach from these alone.
- Then, if it helps, a short list of the main parts: which piece does what, and how they connect. Name a class, file, or endpoint only where the name helps the reviewer find it.
- Do not open with a list of identifiers, types, and value ranges. The reviewer loses the overall idea in the detail.
- Assume the reviewer does not know this area of the code well. Pick the details that help them follow the approach, and leave out the rest.

Weak opening:

> Adds `move_in_on` to `UnitSerializer#as_json` as an ISO 8601 `date`, nullable, read from `leases.start_date`.

Better opening:

> The unit detail response now includes the move-in date from the current lease. Units with no current lease return no date.

### How to Verify

Give the manual steps a reviewer can follow to see the change work: where to go, what to do, and what they should see.

- Write numbered steps, with the expected result at the end.
- Include any setup the steps need, such as a seed, a feature flag, or a test account.
- When nothing can be checked by hand, for example code that nothing calls yet, write one line that says so.

> 1. Open any unit with a current lease in the app.
> 2. Open the unit detail panel.
> 3. The move-in date shows under the lease term. A unit with no current lease shows no date.

### Ticket

A link to the ticket, for example `[APP-1234](<ticket URL>)`. With no ticket, write "No ticket." Do not link a spec, TRD, or other doc instead. In stacked mode, also link the PR this one builds on.
