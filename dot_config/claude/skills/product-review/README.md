# /product-review

Reviews a PRD like a senior product leader — reads the spec, fetches linked assets, identifies gaps, and produces a structured Q&A report separating answered questions from items needing stakeholder input.

## Usage

/product-review

**Examples:**
/product-review https://linear.app/team/issue/PROJ-123
/product-review docs/specs/checkout-redesign.md
/product-review <pasted PRD text>

## What it does

| Step | What happens |
|------|-------------|
| 0 | Resolves the PRD from a URL, file path, or pasted text; fetches linked assets (mockups, Figma frames, linked docs) |
| 1 | Outputs a comprehension summary for sanity-checking before proceeding |
| 2 | Runs category-driven gap analysis across 11 dimensions |
| 3 | Asks each question one at a time with suggested answers and a "defer to stakeholder" option |
| 4 | Saves a structured report to `docs/product-reviews/` and prints a summary |

## Gap analysis categories

User Stories & Personas, Scope & Boundaries, UX & Interaction Design, Data Model & State, Business Rules & Logic, Error Handling & Edge Cases, Performance & Scale, Security & Permissions, Dependencies & Integrations, Rollout & Migration, Analytics & Success Metrics.

## Notes

- Accepts URLs, file paths, or inline text as input
- Fetches and analyzes linked assets including Figma mockups
- Questions are ordered most-impactful first
- Report separates answered questions from those needing stakeholder follow-up
