# /explain-project-deck

Builds a short briefing deck for a project, so you can understand it well enough to sign off in one sitting instead of a week of reading the plan, TRD and tickets.

## What it does

Reads the project's vault brief, technical plan, TRD and original request, traces the real code in the area, and publishes a 14-slide HTML deck as an Artifact. The deck stays at the "what and why" level: names of things, params and per-ticket detail stay out. The source is saved to the project's vault `Artifacts/` folder.

The 14 slides, in order:

1. What it is, in one sentence
2. Why we're doing it
3. The user's journey
4. Then vs now
5. Architecture today
6. Architecture after (same layout as slide 5)
7. What we reuse on purpose
8. Key decisions, with the alternatives rejected
9. Risks and their guards
10. Out of scope
11. Sequencing (waves and critical path, no statuses)
12. How it ships and how to undo it
13. Open questions, with owners
14. Sign-off questions, with answers you can reveal

## Usage

```
/explain-project-deck                     # the current work project
/explain-project-deck <Linear project>    # a named project
```

## When to use

- After `/technical-plan`, before you approve the plan
- Again after the TRD, if the sequencing changed a lot
- Any time a project is too big to hold in your head from the docs alone

## Things to remember

- The deck is a **snapshot at sign-off**. It is never kept up to date, and it never shows statuses.
- Progress belongs on a **separate live sequencing page** for complex projects (see the vault note "Sequencing Page Design Method").
- Slides 5 and 6 are the only place class names appear, because their job is to show what you're building on top of.
- Every visual mark on a slide must be in a legend. The first test deck taught this: unexplained blue outlines were confusing.

## Requirements

- A technical plan must exist. The skill stops without one.
- The repo the project touches must be available, to trace the architecture.
- Artifacts must be available to publish the deck.

## Relationship to other skills

- **Reads what** `/start-work-project`, `/technical-plan` and `/technical-requirements-document` **write**
- **Separate from the live sequencing page**, which the project's planner session keeps current
- **Status: draft.** First built for New Market Survey Endpoints (October 2026). Not yet tested on a second project.
