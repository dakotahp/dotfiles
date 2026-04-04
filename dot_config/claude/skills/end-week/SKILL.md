---
name: end-week
description: Weekly cofounder session — surveys the past week's vault activity, selects the highest-leverage project to focus on, and does autonomous adaptive work (research, planning, structuring, decision-surfacing). Writes a weekly summary note with decisions surfaced. Non-interactive.
allowed-tools: Bash, Read, Edit, Write, WebSearch, WebFetch
---

Weekly cofounder and personal assistant session. Works through three phases autonomously: survey the week, pick the highest-leverage project, do real work on it. Surfaces key decisions at the end — does not ask questions during the run.

Vault: ObsidianPersonal. All obsidian commands use `vault=ObsidianPersonal` immediately after the subcommand.

---

## Phase 1 — Survey

Calculate the date range and get the ISO week number:

```bash
TODAY=$(date +%Y-%m-%d)
WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d)
WEEK_NUM=$(date +%Y-%V)
echo "Week: $WEEK_NUM | Range: $WEEK_AGO to $TODAY"
```

Read all context before doing any analysis. Run these in sequence:

```bash
# Strategic context
obsidian read vault=ObsidianPersonal path="2_Areas/Life Domains.md"

# Deferred items
obsidian read vault=ObsidianPersonal path="2_Areas/Personal Knowledge Management/Avoidance Radar.md"

# List archived daily notes — filter to past 7 days by filename
obsidian files vault=ObsidianPersonal folder="4_Archive/Daily Notes"

# Project velocity — modification timestamps on Index files
find /home/neropol/Syncthing/ObsidianPersonal/1_Projects -maxdepth 2 -name "Index.md" -printf "%T@ %p\n" | sort -rn

# Idea stubs waiting for attention
obsidian search vault=ObsidianPersonal query="tag:#stub" format=json
```

From the archived daily notes list, filter to files whose YYYY-MM-DD filename falls within the past 7 days. Read the `## Distillation` section of each — specifically the "Day in brief" sentence and the **Action items** list. Skip notes with no Distillation section (empty days).

If fewer than 2 daily notes exist in the 7-day window, note this as a low-data week — proceed with what's available, don't abort.

Read each project's `Index.md`:

```bash
obsidian read vault=ObsidianPersonal path="1_Projects/<project>/Index.md"
```

Do this for every project listed under `1_Projects/`. The Index.md files contain the `#agent-context` content that describes each project's current state.

**Internal picture to build (not written yet):**
- Which domains were active in the week's distillations vs. absent
- Which projects had vault activity vs. went silent
- What's accumulating on the Avoidance Radar and for how long
- What idea stubs exist and what projects they relate to (judge by content, not formal links)
- Any `## Feedback` sections on existing notes in project folders (scan while reading)

---

## Phase 2 — Project Selection

Score each project against four signals. Higher score = stronger case to focus here this week.

| Signal | How to score |
|--------|-------------|
| **Strategic priority** | Read from Life Domains — Chemo Navigator rates highest, then LetsConnect.lol, then idea stubs. Use the domain's described priority/cadence as weight. |
| **Neglect duration** | Convert `find` timestamps to days-ago. More days since any file in the project folder was touched = higher score. A project touched yesterday scores 0 here. |
| **Idea stubs waiting** | Count stubs from `0_Inbox` whose content is semantically about this project. Each related stub adds to the score. |
| **Phase readiness** | Can useful work happen right now without the user present? A project waiting on an external reply scores low. A project with clear gaps in documentation or strategy scores high. |

**Archive flag check:** If a project's last-modified timestamp is 60+ days ago AND its Index.md gives no signal of intentional pause, flag it as "is this still active?" rather than scoring it. Do not do depth dive work on archive-candidate projects — surface the question in the weekly output note instead.

**Feedback check:** If any project's notes contain a `## Feedback` section with content saying "shelving" or "not active" or similar, exclude it from scoring.

Pick the highest-scoring project. Announce before diving in:

> *"Focusing on [Project Name] this week — [one sentence stating the primary reason]."*

---

## Phase 3 — Depth Dive

Read the chosen project thoroughly, starting with what matters most:

1. Recall the `Index.md` already read in Phase 1
2. Read any notes tagged `#agent-context` in the project folder
3. Check for `## Feedback` sections on any existing notes — incorporate this before doing any new work
4. Read recently modified notes (use modification timestamps to prioritize)
5. For large projects (20+ notes), stop reading individual files once you have enough to form a diagnosis — don't read every technical reference note

```bash
# List all files in chosen project folder
obsidian files vault=ObsidianPersonal folder="1_Projects/<chosen>"

# Get modification timestamps to find recently touched notes
find /home/neropol/Syncthing/ObsidianPersonal/1_Projects/<chosen> -name "*.md" -printf "%T@ %p\n" | sort -rn | head -10
```

**Form a diagnosis before doing any work.** Answer these questions internally:
- What phase is this project in? (idea → validation → building → shipped → stalled → drifting)
- What's the most valuable thing that doesn't exist yet in this folder?
- What would a cofounder do right now if handed this project cold?
- What does the feedback say, if any?

**Then do the work.** The work type depends on the diagnosis:

| Diagnosis | Work |
|-----------|------|
| Active, missing scaffolding | Create the document that should exist but doesn't — a marketing brief, a go-to-market skeleton, a competitive positioning doc, a technical plan stub. Use web research to inform it. |
| Stalled at a decision | Research the decision space. Create a decision brief: what needs to be decided, what are the options, what are the tradeoffs, which choice unlocks the most. |
| Idea stubs floating | Gather related stubs from `0_Inbox`. Create a structured note that consolidates them with a next-step recommendation. |
| Shipped, no traction (e.g. LetsConnect) | Research what comparable early-stage products do for traction. Draft a promotion or growth strategy note scoped to realistic time/effort. |
| Discovery phase (e.g. Chemo Navigator) | Synthesize what's been learned so far across all discovery notes. Identify gaps in the discovery thesis. Propose the next 3-5 highest-value questions to explore. |

**Use web research when useful.** If the project needs external context — competitive landscape, comparable examples, market data, traction strategies — use WebSearch and WebFetch. Don't synthesize from the vault alone when real-world data would make the output more useful.

**Create work products as notes in the project folder:**

```bash
obsidian create vault=ObsidianPersonal path="1_Projects/<chosen>/<Descriptive Title>.md" content="---\ntags:\n  - agent-work\ncreated: YYYY-MM-DD\n---\n\n[content]\n\n## Feedback\n" silent
```

Every skill-produced note gets:
- `tags: agent-work` in frontmatter
- An empty `## Feedback` section at the bottom

**Update the project's Index.md:**

```bash
obsidian append vault=ObsidianPersonal path="1_Projects/<chosen>/Index.md" content="\n---\n\n**Last worked: YYYY-MM-DD** (via /end-week) — [one sentence describing what was produced]"
```

---

## Phase 4 — Weekly Output Note

Write a summary note after all work is complete. Get the week number first:

```bash
WEEK_NUM=$(date +%Y-%V)
```

Create the note at `4_Archive/Weekly Notes/$WEEK_NUM.md`:

```bash
obsidian create vault=ObsidianPersonal path="4_Archive/Weekly Notes/$WEEK_NUM.md" content="[full content]" silent
```

The note structure:

```markdown
---
tags:
  - weekly-note
week: YYYY-WW
---

## Week in Brief

[2-3 sentences: what moved this week, what didn't, dominant themes from daily distillations]

## Domain Gaps

Domains from Life Domains with zero activity in the week's daily notes:
- [Domain name] — no mentions in any daily note this week

(Omit this section if all domains had at least some representation.)

## Project Focused

**[Project Name]** — [reason it was chosen]

## Work Produced

- [[Note title]] — [one sentence on what it is]

## Decisions Needed

Questions requiring your input before work can continue:

1. [Specific decision with enough context to answer it]

(Omit if no decisions needed.)

## Archive Candidates

Projects not touched in 60+ days with no clear pause signal:
- [[Project Name]] — last activity: YYYY-MM-DD. Still active?

(Omit if no candidates.)
```

---

## Done

The weekly note and work products are in place. No further output needed.
