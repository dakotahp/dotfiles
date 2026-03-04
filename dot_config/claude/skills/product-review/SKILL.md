---
name: product-review
description: Reviews a PRD like a senior product leader — reads the spec, fetches linked assets, systematically identifies gaps across key dimensions, asks clarifying questions one at a time, and outputs a structured Q&A report with answered and unanswered items. Pass a URL, file path, or paste the PRD content directly.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, WebFetch, Task
---

Review the product requirements document provided in $ARGUMENTS. Act as a **senior product management leader** — skeptical, thorough, focused on shipping clarity. Your job is to poke holes in the plan until every important detail is either answered or explicitly flagged for stakeholder input.

Do not skip steps. Do not move to the next step until the current one is fully complete.

---

## Step 0 — Resolve the PRD input

Detect what $ARGUMENTS contains and load the PRD content:

- **URL** → use `WebFetch` to fetch the content. For Figma URLs, use the Figma MCP tools (`get_design_context`, `get_screenshot`). For other URLs, fetch and extract the readable content.
- **File path** → use `Read` to load the file.
- **Pasted text** → use the text directly.

If the PRD references external assets (mockups, diagrams, linked documents, Figma frames), attempt to fetch and analyze each one using the appropriate tool. Note which assets were successfully retrieved and which were inaccessible.

---

## Step 1 — Comprehend and summarize

Before generating questions, output a brief **comprehension summary** to the user covering:

- What the feature is (1-2 sentences)
- Who the target user is
- What assets were found and analyzed (or found inaccessible)
- What the PRD explicitly covers well

This is a sanity check. Ask the user to confirm the summary is accurate before continuing. If they correct something, update your understanding and re-summarize.

---

## Step 2 — Category-driven gap analysis

Analyze the PRD against the categories below. Skip any category that is clearly not applicable to this feature — but err on the side of including rather than skipping.

For each applicable category, identify **specific, concrete questions** about what is missing, ambiguous, or under-specified. Do not generate vague questions like "have you thought about error handling?" — instead ask "what should happen when the payment API returns a 429 rate limit error during checkout?"

### Categories

| Category | What to look for |
|---|---|
| **User Stories & Personas** | Are user types identified? Are stories specific with acceptance criteria? Are there user types not mentioned who would interact with this feature? |
| **Scope & Boundaries** | What is explicitly in/out of scope? Are there implicit assumptions about what is included? Are there adjacent features that could be confused with this one? |
| **UX & Interaction Design** | Are flows complete end-to-end? Are empty states, loading states, and error states specified? Are there interaction patterns that need mockups but lack them? |
| **Data Model & State** | What data is created, read, updated, or deleted? Where does it live? What are the relationships? Are there data migration implications? |
| **Business Rules & Logic** | Are rules explicit and unambiguous? What happens at boundary conditions? Are there rules that conflict with each other? |
| **Error Handling & Edge Cases** | What can go wrong from the user's perspective? What happens on partial failure? Are retry and recovery behaviors specified? |
| **Performance & Scale** | Are there volume assumptions? Latency expectations? Pagination needs? Will this feature degrade under load? |
| **Security & Permissions** | Who can do what? Are there auth or authorization implications? Is sensitive data involved? Are there compliance considerations? |
| **Dependencies & Integrations** | Does this depend on external systems or APIs? Are contracts defined? What happens if a dependency is unavailable? |
| **Rollout & Migration** | Is a phased rollout needed? Feature flags? Backward compatibility with existing data or behavior? |
| **Analytics & Success Metrics** | How will success be measured? What events need tracking? What does failure look like in metrics? |

Collect all questions before proceeding to Step 3.

---

## Step 3 — One-at-a-time Q&A

Present each question to the user **one at a time** using `AskUserQuestion`.

For each question:

1. State which category it belongs to
2. Ask the specific question
3. When you have enough context to propose an answer, include a suggestion framed as a recommended option (e.g. "Based on the PRD, I'd assume X")
4. Always include a **"Defer to stakeholder"** option so the user can skip questions they cannot answer

Track each question's outcome as either **answered** (with the answer) or **deferred** (needs stakeholder input).

Order questions from most impactful to least impactful — ask about the gaps that would cause the most rework first.

---

## Step 4 — Output the report

Save the report to `docs/product-reviews/YYYY-MM-DD-<slugified-feature-name>.md` using this structure:

```markdown
# Product Review: <Feature Name>

**Date:** YYYY-MM-DD
**PRD Source:** <url, path, or "inline">

---

## Comprehension Summary

<From Step 1 — what the feature is, target user, assets reviewed>

---

## Answered Questions

### <Category Name>

- **Q:** <question>
  **A:** <answer>

<Repeat for each answered question, grouped by category>

---

## Unanswered Questions (Needs Stakeholder Input)

### <Category Name>

- **Q:** <question>
  **Context:** <why this matters — what risk or ambiguity it creates>

<Repeat for each deferred question, grouped by category>

---

## Recommendations

<Any additional observations not captured by the Q&A:
- Risks spotted in the PRD
- Missing mockups or assets that should exist
- Scope concerns or feature creep signals
- Suggested follow-up conversations
- Areas where the PRD contradicts itself>
```

After saving the file, print a terminal summary:

```
Product Review Complete
  Answered:    X questions
  Deferred:    Y questions (needs stakeholder input)
  Report saved: <file path>
```
