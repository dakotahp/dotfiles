# /onboard

Analyzes any repository and produces a structured onboarding report for a developer who is new to it. Covers tech stack, architecture, entry
points, conventions, testing, dev workflow, and gotchas.

## Usage

/onboard

**Examples:**
/onboard
/onboard authentication
/onboard the payment processing flow

With no arguments, produces a full repo overview. With an argument, includes everything plus a dedicated deep-dive on that specific area or
module.

## What it produces

- What the project is and does
- Tech stack and key dependencies
- Annotated project structure
- How to install, run, and test it
- Architecture style and key patterns
- The 3–6 most important files to read first
- Data layer, state management, and key env vars
- CI/CD overview
- Gotchas and non-obvious things
- Focused deep-dive (if an area was specified)

## Notes

- Read-only — makes no changes to the codebase
- Collects all findings before outputting, so the report arrives as a single structured document
- Run from the root of the repository you want to understand
