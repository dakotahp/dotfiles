---
name: end-week
description: Weekly cofounder session — surveys the past week's vault activity, scores top-candidate projects, presents a multi-select menu of candidate work products for the user to curate, then executes the selected deep dives (research, planning, structuring, decision-surfacing). Writes a decisions-first weekly summary note. One curation checkpoint; otherwise autonomous.
allowed-tools: Bash, Read, Edit, Write, WebSearch, WebFetch, AskUserQuestion
model: claude-opus-4-7
---

Weekly cofounder and personal assistant session. Works through four phases: survey the week, score and diagnose top-candidate projects, present a multi-select menu of candidate work products, then execute the user's selections. One curation checkpoint in the middle; everything else runs autonomously.

Vault: ObsidianPersonal. All obsidian commands use `vault=ObsidianPersonal` immediately after the subcommand.

---

## Phase 1 — Survey

Calculate the date range anchored to the most recently completed Sunday — so the skill always reviews the week that just ended, whether run on Sunday itself or days later:

```bash
# DOW: 1=Mon … 6=Sat, 7=Sun. Days since last Sunday = DOW % 7 (0 if today IS Sunday).
DOW=$(date +%u)
DAYS_BACK=$(( DOW % 7 ))
WEEK_END=$(date -d "$DAYS_BACK days ago" +%Y-%m-%d)
WEEK_START=$(date -d "$WEEK_END - 6 days" +%Y-%m-%d)
WEEK_NUM=$(date -d "$WEEK_END" +%Y-%V)
echo "Week: $WEEK_NUM | Range: $WEEK_START to $WEEK_END | Run date: $(date +%Y-%m-%d)"
```

This handles late runs automatically: running on Monday reviews the Sunday-ending week, not the new week that started today.

Read all context before doing any analysis. Run these in sequence:

```bash
# Vault-scope agent context — global personal frame (Life Domains, Avoidance Radar, etc.)
# Returns every file with `agent-context: vault` in frontmatter; read each.
obsidian vault=ObsidianPersonal search query="[agent-context:vault]" format=json

# List archived daily notes — filter to past 7 days by filename
obsidian files vault=ObsidianPersonal folder="4_Archive/Daily Notes"

# Project velocity — prefer authoritative `last-touched` frontmatter, fall back to file mtime.
# `last-touched` is written by /snapshot and /log. Files without it haven't had a session-skill
# run yet — fall back to mtime (less reliable across Syncthing devices, but a usable starting signal).
obsidian vault=ObsidianPersonal search query="[last-touched]" format=json
find /home/neropol/Syncthing/ObsidianPersonal/1_Projects -maxdepth 2 \( -name "Index.md" -o -name "*.md" \) -printf "%T@ %p\n" | sort -rn

# Idea stubs waiting for attention
obsidian search vault=ObsidianPersonal query="tag:#stub" format=json
```

From the archived daily notes list, filter to files whose YYYY-MM-DD filename falls between WEEK_START and WEEK_END (inclusive). Do not include notes dated after WEEK_END — those belong to the next week's run. Read the `## Distillation` section of each — specifically the "Day in brief" sentence and the **Action items** list. Skip notes with no Distillation section (empty days).

If fewer than 2 daily notes exist in the 7-day window, note this as a low-data week — proceed with what's available, don't abort.

Read each project's `Index.md`:

```bash
obsidian read vault=ObsidianPersonal path="1_Projects/<project>/Index.md"
```

Do this for every project listed under `1_Projects/`. The Index.md files typically carry `agent-context: project` and describe each project's current state.

**Internal picture to build (not written yet):**
- Which domains were active in the week's distillations vs. absent
- Which projects had vault activity vs. went silent
- What's accumulating on the Avoidance Radar and for how long
- What idea stubs exist and what projects they relate to (judge by content, not formal links)
- Any `## Feedback` sections on existing notes in project folders (scan while reading)

**Stale agent-context check.** While reading agent-context files in this phase, capture each file's `last-reviewed` frontmatter date (or note its absence). Any file with `last-reviewed` 60+ days ago, or missing the field entirely, is a candidate to surface in `## Stale Context` in the weekly note (Phase 4). Do not edit these files in this skill — the user runs `/refresh-context` for that.

---

## Phase 2 — Score, Diagnose, Curate

This phase has three sub-steps: score every project, do lightweight diagnosis on the top candidates and propose work products for each, then present them to the user as a multi-select menu.

### Phase 2a — Score all projects

Score each project against four signals. Higher score = stronger case to focus here this week.

| Signal | How to score |
|--------|-------------|
| **Strategic priority** | Read from Life Domains — Chemo Navigator rates highest, then LetsConnect.lol, then idea stubs. Use the domain's described priority/cadence as weight. |
| **Neglect duration** | Prefer the canonical file's `last-touched` frontmatter (authoritative — written by `/snapshot` and `/log`). Fall back to `find` mtime only if `last-touched` is absent. More days since last touch = higher score. A project touched yesterday scores 0 here. |
| **Idea stubs waiting** | Count stubs from `0_Inbox` whose content is semantically about this project. Each related stub adds to the score. |
| **Phase readiness** | Can useful work happen right now without the user present? A project waiting on an external reply scores low. A project with clear gaps in documentation or strategy scores high. |

**Archive flag check:** If `last-touched` (or mtime fallback) is 60+ days ago AND its Index.md gives no signal of intentional pause, flag it as "is this still active?" rather than scoring it. Do not propose work products for archive-candidate projects — surface the question in the weekly output note instead.

**Feedback check:** If any project's notes contain a `## Feedback` section with content saying "shelving" or "not active" or similar, exclude it from scoring.

Take the **top 3-4 scoring projects** as candidates. The remainder are excluded from this week's depth-dive options.

### Phase 2b — Lightweight diagnosis + propose work products per candidate

For each top-candidate project, do a focused diagnosis (faster than the original Phase 3 deep read — just enough to propose work):

1. Recall the `Index.md` already read in Phase 1
2. Read any notes with `agent-context: project` in the project folder:
   ```bash
   obsidian vault=ObsidianPersonal search path="1_Projects/<candidate>" query="[agent-context:project]" format=json
   ```
3. Read all `## Feedback` sections from notes in the project folder — these are user steering signals and must shape proposed work
4. Skim recently modified notes (last 14 days) to understand current state

Form a diagnosis (idea → validation → building → shipped → stalled → drifting) and propose **1-2 candidate work products**. Use the diagnosis-to-work mapping:

| Diagnosis | Candidate work product |
|-----------|----------------------|
| Active, missing scaffolding | A specific document that should exist but doesn't — marketing brief, GTM skeleton, competitive positioning, technical plan stub |
| Stalled at a decision | A decision brief: what needs deciding, options, tradeoffs, which choice unlocks the most |
| Idea stubs floating | A consolidation note gathering related stubs with a next-step recommendation |
| Shipped, no traction | A traction strategy note grounded in comparable products' tactics |
| Discovery phase | A synthesis of what's been learned + 3-5 highest-value next discovery questions |

When generating multiple options for one project, make them **distinct angles** — not the same work product reworded. E.g. for Chemo Navigator: one option could be "synthesize warm-network discovery approach" and a second could be "research cold-call playbooks for community oncology" — both valid, different focus.

**Use feedback as a hard constraint.** If a project's notes say "prioritize warm network over cold names," do not propose a cold-name work product. The feedback section is authoritative.

### Phase 2c — Multi-select checkpoint

Present the candidate work products as a single multi-select question. Group options under per-project headers. Cap at 6-7 total candidates.

Use `AskUserQuestion` with `multiSelect: true`. Each option's `label` is the work product name (concise, 5-8 words); each `description` is one sentence describing what would be produced and why it's valuable now. The question header should reference the project; the question body should be brief.

Example shape (illustrative — actual content driven by Phase 2b):

```
Question: "Which deep dives should I do this week?"
multiSelect: true
options:
  - label: "Chemo Navigator: synthesize warm-network discovery"
    description: "Consolidate this week's discovery notes; propose next 3-5 questions scoped to wife's network. Defers cold-call work per feedback."
  - label: "Chemo Navigator: COA Conference go/no-go brief"
    description: "Decision brief weighing $1.2k travel + 2 days vs Phase 3 procurement signal. Resolves the open weekly decision."
  - label: "LetsConnect.lol: traction tactics from comparable products"
    description: "Research 4-5 early-stage growth playbooks; draft a 2hrs/week promotion plan."
  - label: "Idea stub consolidation: warm network mapping"
    description: "Merge 3 related stubs in 0_Inbox into a structured next-step note for Chemo Navigator."
```

After the user responds:
- **One or more selected:** proceed to Phase 3, looping over each selected work product
- **Zero selected:** skip Phase 3 entirely, proceed straight to Phase 4. The weekly summary still gets written; `## Work Produced` shows "None — by user choice."

---

## Phase 3 — Execute Selected Work Products

For each work product the user selected, execute it as a standalone task. If multiple were selected, do them sequentially.

For each selected item:

1. Re-anchor on the project's diagnosis from Phase 2b (already in memory)
2. Do the work — synthesize, draft, research as needed
3. **Use web research when useful.** If the work product needs external context — competitive landscape, comparable examples, market data, traction strategies — use WebSearch and WebFetch. Don't synthesize from the vault alone when real-world data would make the output more useful.
4. **Create the work product as a note in the project folder:**

   ```bash
   obsidian create vault=ObsidianPersonal path="1_Projects/<project>/<Descriptive Title>.md" content="---\ntags:\n  - agent-work\ncreated: YYYY-MM-DD\n---\n\n[content]\n\n## Feedback\n" silent
   ```

   Every skill-produced note gets:
   - `tags: agent-work` in frontmatter
   - An empty `## Feedback` section at the bottom

5. **Update the project's Index.md:**

   ```bash
   obsidian append vault=ObsidianPersonal path="1_Projects/<project>/Index.md" content="\n---\n\n**Last worked: YYYY-MM-DD** (via /end-week) — [one sentence describing what was produced]"
   ```

If the same project has multiple selected work products, append one Index.md update per work product (don't batch).

---

## Phase 4 — Weekly Output Note

Write a summary note after all work is complete. Use the WEEK_NUM already computed in Phase 1 (derived from WEEK_END, not today's date — so a Monday run still produces the correct week number).

Create the note at `4_Archive/Weekly Notes/$WEEK_NUM.md`:

```bash
obsidian create vault=ObsidianPersonal path="4_Archive/Weekly Notes/$WEEK_NUM.md" content="[full content]" silent
```

The note structure (decisions-first — the load-bearing section is at the top so a quick read surfaces what needs your input):

```markdown
---
tags:
  - weekly-note
week: YYYY-WW
---

## Decisions Needed

Questions requiring your input before work can continue:

1. [Specific decision with enough context to answer it]

(Omit this section if no decisions surfaced. To resolve a decision, edit it in place — strikethrough or add **Decided:** inline. start-day reads this section as ambient context.)

## Projects Focused

For each project that had work products selected and executed:

**[[Project Name]]** — [why it was picked + brief framing]

## Work Produced

- [[Note title]] — [one sentence on what it is and which project]

(If user selected zero work products: write "None — by user choice." instead of a list.)

## Not Selected This Week

Candidate work products surfaced in the multi-select but not picked. Listed for next week's scoring memory and for your reference if priorities shift.

- **[[Project Name]]:** [Work product label] — [one-line description]

(Omit this section if all candidates were selected, or if no candidates were generated.)

## Week in Brief

[2-3 sentences: what moved this week, what didn't, dominant themes from daily distillations]

## Domain Gaps

Domains from Life Domains with zero activity in the week's daily notes:
- [Domain name] — no mentions in any daily note this week

(Omit this section if all domains had at least some representation.)

## Archive Candidates

Projects not touched in 60+ days with no clear pause signal:
- [[Project Name]] — last activity: YYYY-MM-DD. Still active?

(Omit if no candidates.)

## Stale Context

Agent-context files (vault/project/area scope) with `last-reviewed` 60+ days old or missing. These shape automatic agent framing — drift here misdirects everything downstream. Run `/refresh-context` to walk through them.

- [[File path]] — last-reviewed: YYYY-MM-DD (or "never")

(Omit if all agent-context files are within 60 days.)
```

---

## Done

The weekly note and work products are in place. No further output needed.
