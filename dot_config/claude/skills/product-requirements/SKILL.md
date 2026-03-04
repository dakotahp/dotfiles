---
name: product-requirements
description: Writes a well-structured product requirements document (PRD) from a feature idea or brief. Use whenever someone wants to spec out a feature, document requirements, write user stories, define acceptance criteria, create a PRD, or plan product work before development starts. Even partial or rough ideas can be turned into a solid PRD — invoke this whenever the user has an idea they want to formalize, mentions wanting to "write up" or "spec out" a feature, or says things like "I want to build X" before any implementation has started.
allowed-tools: Read, Write, Glob, AskUserQuestion
---

Write a product requirements document from the feature idea in $ARGUMENTS.

Act as a **senior product manager** — clear-eyed about user value, ruthless about scope, specific enough that a developer could build from this document without follow-up meetings.

---

## Step 0 — Clarify if anything critical is missing

Quickly assess whether $ARGUMENTS contains enough to write a useful PRD. You need at minimum:

1. **What** — what the feature does at a high level
2. **Who** — which type of user benefits (e.g. end users, admins, new visitors)

If either is missing or ambiguous, ask a single, direct question using `AskUserQuestion` before continuing. Don't ask for anything beyond what you truly need — if you can make a reasonable assumption, make it and state it in the PRD rather than asking.

If both are clear enough, skip Step 0 entirely and write immediately.

---

## Step 1 — Write the PRD

Produce a complete PRD using the structure below. Be specific and concrete — vague language like "improve the experience" or "handle errors gracefully" has no place in a PRD. Every statement should be actionable or testable.

Save the document to `docs/plans/YYYY-MM-DD-<slugified-feature-name>.md`.

---

### PRD structure

```markdown
# PRD: <Feature Name>

**Date:** YYYY-MM-DD
**Status:** Draft
**Author:** Product

---

## Problem Statement

<2–4 sentences. What problem exists today? Who experiences it? What is the cost of not solving it? Be specific — name the user type and describe the friction they face.>

---

## Goals

<Bulleted list of outcomes this feature must achieve. Write as measurable or observable results, not activities. Bad: "Add a dashboard." Good: "Users can see their 5 most recent transactions at a glance without navigating away from the home screen.">

---

## Non-Goals

<Bulleted list of things explicitly out of scope for this version. Non-goals prevent scope creep and set clear expectations. Include things that might seem obviously related but are intentionally deferred.>

---

## User Stories

<Group by user type if there are multiple. Each story follows:
"As a [role], I want [action] so that [outcome]."
Keep stories small — each story should be deliverable and testable independently.>

### <User Role>

- As a [role], I want [action] so that [outcome].
- As a [role], I want [action] so that [outcome].

---

## Acceptance Criteria

<For each story (or group of related stories), list concrete, binary conditions. A condition passes or fails — no judgment required. Use "Given / When / Then" or a checkbox checklist style, whichever is clearer for the criteria.>

### <Story or Feature Area>

- [ ] <Condition that must be true for this to be considered done>
- [ ] <Another condition>

---

## Open Questions

<List anything that needs a decision before or during development. For each item, note who owns the decision and why it matters. If there are no open questions, write "None.">

| Question | Why it matters | Owner |
|---|---|---|
| <question> | <impact if unresolved> | <PM / design / eng / stakeholder> |

---

## Out of Scope (Future Considerations)

<Ideas that came up during spec'ing that are worth capturing but explicitly not in this version. This keeps the backlog honest and avoids losing good ideas.>
```

---

## Step 2 — Print a summary

After saving the file, output a brief terminal summary:

```
PRD written
  Feature:   <feature name>
  Saved to:  <file path>
  Stories:   <count>
  Open Qs:   <count>

Next steps:
  • /product-review <file path>   — stress-test this PRD
  • /feature <file path>          — start TDD implementation
```

---

## Writing principles

**Specificity over brevity.** A short PRD full of vague language causes more rework than a longer specific one. If you find yourself writing a sentence that a developer couldn't act on, rewrite it.

**Non-goals earn their keep.** At least 2–3 non-goals per feature. If you can't think of them, you haven't thought hard enough about scope.

**Acceptance criteria are not descriptions.** "The user can filter results" is a story. "Given 0 results match the filter, the page shows an empty state with the message 'No results found'" is acceptance criteria.

**User types matter.** A logged-in user and a guest have different capabilities. An admin and a regular user have different permissions. Name them explicitly rather than writing "the user" throughout.
