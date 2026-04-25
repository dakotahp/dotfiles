---
name: save-takeaways
description: Distills takeaways from **cross-project or non-project** exploratory conversations (business ideas, competitive analysis, technical investigations, strategy discussions not yet anchored to a project) and saves them to the Obsidian vault. Insights and decisions go to a standalone 0_Inbox note (persists for later filing). Action items go to the daily note (picked up by start-day rollover). Use when the user says "save takeaways", "capture takeaways", "what did I learn", "save what we discussed", or invokes /save-takeaways. **For conversations anchored to a 1_Projects/ or 2_Areas/ folder, use `/preserve` instead** — that writes to the project's canonical Session Context, which is the right home for project-scoped insights.
allowed-tools: Bash, AskUserQuestion
---

Scan the current conversation and distill takeaways into three categories. This skill is for **cross-project or non-project exploratory conversations** — the catch-all for thinking that doesn't yet belong to a project folder. Insights and decisions land in `0_Inbox/` so they persist for filing later. Action items go to today's daily note so `start-day` can roll them forward.

For project-anchored conversations, `/preserve` is the right tool — it writes structured Session Context to the project's canonical file. `save-takeaways` and `/preserve` should not be used together on the same conversation.

## Step 1 — Scope check (project-anchored?)

Determine whether the current conversation is project-anchored:

- Walk up from `pwd`. If an ancestor folder is named `1_Projects` or `2_Areas`, the immediate child is the active project/area. Capture that name.
- If no such ancestor exists, you're in cross-project territory — proceed to Step 2.

**If a project/area was detected**, ask the user before proceeding:

> "You're in `{Category}/{ProjectName}/`. This skill is for cross-project conversations — for project work, `/preserve` writes to that project's Session Context, which is usually the right home.
>
> Was this conversation actually about `{ProjectName}`, or was it about something else?"

Use AskUserQuestion with options:
1. **About {ProjectName}** — stop and suggest `/preserve "{ProjectName}"`
2. **Something else (proceed with takeaways)** — continue to Step 2
3. **Mixed (proceed, I'll file later)** — continue to Step 2

Only continue if the user picks option 2 or 3. If they pick 1, output: `"Use /preserve "{ProjectName}" instead — it'll write to the project's Session Context."` and stop.

## Step 2 — Determine topic label

If `$ARGUMENTS` is provided, use it as the topic label. Otherwise, infer a short 3-6 word descriptor from the conversation (e.g., "B2B pricing strategy exploration", "React Server Components feasibility").

## Step 3 — Distill takeaways

Scan the full conversation and extract content into three sections:

### Key Insights
Facts, conclusions, mental model shifts, surprising findings, and important context. The knowledge that would be lost if not written down. Each bullet should be self-contained — readable and useful without re-reading the conversation.

### Decisions & Positions
Conclusions reached, stances taken, options evaluated and ruled out (with reasoning). These represent commitments or landing points, not just information. Include the *why* so future-you understands the reasoning.

### Action Items
Concrete next steps where the user expressed **explicit intent to act** — something to build, test, reach out about, or decide. Each item should be specific enough to act on without re-reading the conversation. Use `- [ ]` checkbox syntax so they appear in Obsidian task queries.

**Do not extract as action items:**
- Passive mentions of resources (books, articles, tools) referenced for context or analogy, unless the user said they plan to read/use them
- Speculative or hypothetical steps ("one could...", "it might be worth...")
- Things already tracked elsewhere (existing todos, Avoidance Radar items)
- Background knowledge that informed the conversation but requires no follow-up

**Guidelines for all sections:**
- Omit a section entirely if the conversation produced nothing for it (e.g., a pure research conversation may have no action items)
- Favor specificity over brevity — "React Server Components can't do X because of limitation Y" is better than "RSC has limitations"
- Include enough context that each bullet is useful when read cold weeks later
- Don't pad sections — 2 strong bullets beat 6 vague ones

## Step 4 — Save insights and decisions to 0_Inbox

If there are any Key Insights or Decisions & Positions, create a standalone note in `0_Inbox/`:

**Filename:** `Takeaways - {topic label} {YYYY-MM-DD}.md`

**Format:**
```
---
tags:
  - takeaways
---

# Takeaways: {topic label}

*{YYYY-MM-DD} — captured from conversation*

### Key Insights
- Insight one
- Insight two

### Decisions & Positions
- Decision one

*File to the relevant project or area when ready.*
```

Create the note using:
```bash
obsidian create vault="ObsidianPersonal" name="Takeaways - {topic label} {YYYY-MM-DD}" folder="0_Inbox" content="<formatted content>"
```

If there are no Key Insights and no Decisions & Positions, skip this step entirely.

## Step 5 — Append action items to daily note

If there are any Action Items, append them to today's daily note:

```bash
obsidian daily:append vault="ObsidianPersonal" content="<formatted content>"
```

**Format:**
```
## Action Items: {topic label}\n\n- [ ] Action one\n- [ ] Action two\n\n*From takeaways captured {YYYY-MM-DD HH:MM}*
```

If there are no Action Items, skip this step entirely.

## Step 6 — Confirm

Report to the user in one line: what was saved where. Examples:
- "3 insights + 1 decision → `0_Inbox/Takeaways - Chemo Navigator strategy 2026-04-16.md`; 2 action items → daily note."
- "2 insights → `0_Inbox/Takeaways - React RSC feasibility 2026-04-16.md`; no action items."
- "2 action items → daily note; no insights or decisions worth preserving."
