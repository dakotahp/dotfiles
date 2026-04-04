# /end-week

A weekly "life CEO" session. Acts as a cofounder and proactive personal assistant — surveys the week's activity across all life domains, picks the highest-leverage project to focus on, does real autonomous work on it, and surfaces key decisions at the end. No interaction during the run.

## What it does

**Phase 1 — Survey (breadth)**
Reads the full picture before doing anything: daily note distillations from the past 7 days, the Avoidance Radar, Life Domains context, all project Index files (modification timestamps as a velocity signal), and idea stubs in `0_Inbox`. Builds an internal picture of what moved, what stalled, and what's been neglected.

**Phase 2 — Project selection**
Scores each project against four signals: strategic priority (from Life Domains), neglect duration (days since last file touch), related idea stubs waiting in Inbox, and phase readiness (can useful work actually happen right now?). Picks the highest-signal project, announces the choice and reasoning in one sentence, then dives in without asking for confirmation.

Projects with no vault activity in 60+ days and no clear pause signal are flagged as archive candidates rather than worked on.

**Phase 3 — Depth dive**
Reads the chosen project thoroughly (Index first, then `#agent-context` notes, then recent files). Forms a diagnosis before touching anything. Work type adapts to project state:

| Project state | What it does |
|---------------|-------------|
| Active, missing scaffolding | Creates the document that should exist — marketing brief, GTM skeleton, technical plan |
| Stalled at a decision | Researches the decision space, lays out options with tradeoffs |
| Idea stubs floating | Gathers related stubs, gives them structure, proposes a next step |
| Shipped, drifting | Researches comparable products, drafts a promotion/traction strategy |
| Discovery phase | Synthesizes findings, identifies gaps, proposes next questions to explore |

Uses web search when the project needs external context. Creates work product notes in the project folder, each tagged `agent-work` with an empty `## Feedback` section at the bottom.

**Phase 4 — Weekly output note**
Writes a summary to `4_Archive/Weekly Notes/YYYY-WW.md` covering: week in brief, domain gaps, which project was chosen and why, what was produced, decisions that need the user's input, and archive candidates.

## Feedback loop

Every skill-produced note includes an empty `## Feedback` section. Write reactions there in any format. On the next run touching that project, the skill reads the feedback before doing any new work. Writing "shelving this, revisit Q3" tells the skill to skip the project in future scoring.

## Files this skill touches

| File | What happens |
|------|-------------|
| `4_Archive/Weekly Notes/YYYY-WW.md` | Created each run |
| `1_Projects/<chosen>/Index.md` | Appended with "last worked on" entry |
| `1_Projects/<chosen>/<New Work>.md` | Created — content depends on diagnosis |

## Dependencies

Reads from (must exist):
- `2_Areas/Life Domains.md` — strategic priorities and seasonal context
- `2_Areas/Personal Knowledge Management/Avoidance Radar.md` — deferred items
- `4_Archive/Daily Notes/` — past week's distillations
- `1_Projects/*/Index.md` — project velocity signals

## Invocation

```
/end-week
```

Run at the end of the week (Friday afternoon or weekend). Takes 5–15 minutes depending on project complexity and whether web research is needed. No interaction during the run — it announces what it's working on and delivers results.
