---
name: save-takeaways
description: Distills conversation takeaways (insights, decisions, action items) and appends them to the Obsidian daily note. Use when the user says "save takeaways", "capture takeaways", "what did I learn", "save what we discussed", or invokes /save-takeaways. Typically used at the end of exploratory conversations (business ideas, competitive analysis, technical investigations, strategy discussions) but safe to invoke mid-conversation or multiple times.
allowed-tools: Bash
---

Scan the current conversation and distill takeaways into three categories, then append them to the Obsidian daily note. All vault interaction goes through the `obsidian` CLI.

## Step 1 — Determine topic label

If `$ARGUMENTS` is provided, use it as the topic label. Otherwise, infer a short 3-6 word descriptor from the conversation (e.g., "B2B pricing strategy exploration", "React Server Components feasibility").

## Step 2 — Distill takeaways

Scan the full conversation and extract content into three sections:

### Key Insights
Facts, conclusions, mental model shifts, surprising findings, and important context. The knowledge that would be lost if not written down. Each bullet should be self-contained — readable and useful without re-reading the conversation.

### Decisions & Positions
Conclusions reached, stances taken, options evaluated and ruled out (with reasoning). These represent commitments or landing points, not just information. Include the *why* so future-you understands the reasoning.

### Action Items
Concrete next steps: things to research, people to talk to, things to build, prototype, or try. Each item should be specific enough to act on without needing to re-read the conversation. Use `- [ ]` checkbox syntax so they appear in Obsidian task queries.

**Guidelines for all sections:**
- Omit a section entirely if the conversation produced nothing for it (e.g., a pure research conversation may have no action items)
- Favor specificity over brevity — "React Server Components can't do X because of limitation Y" is better than "RSC has limitations"
- Include enough context that each bullet is useful when read cold weeks later
- Don't pad sections — 2 strong bullets beat 6 vague ones

## Step 3 — Append to daily note

Format the output as a single markdown block and append it to the daily note using the active vault:

```bash
obsidian daily:append content="<formatted content>"
```

Use `\n` for newlines in the content string.

### Output format

```
## Takeaways: {topic label}\n\n### Key Insights\n- Insight one\n- Insight two\n\n### Decisions & Positions\n- Decision one\n- Decision two\n\n### Action Items\n- [ ] Action one\n- [ ] Action two\n\n*Captured {YYYY-MM-DD HH:MM}*
```

- Omit any section that has no items (don't include an empty header)
- The `##` header level nests cleanly under the daily note's `#` title
- The timestamp distinguishes multiple invocations on the same day

After appending, confirm to the user with a one-line message: how many items were captured across how many sections.
