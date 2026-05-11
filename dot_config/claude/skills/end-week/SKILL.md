---
name: end-week
description: Use at the end of the week to review vault activity, set a weekly focus, curate deep-dive work products, and write the weekly summary note.
allowed-tools: Bash, Read, Edit, Write, WebSearch, WebFetch, AskUserQuestion
model: claude-opus-4-7
---

Weekly review session. Works through four phases: survey the week, score top-candidate projects + capture a weekly focus + diagnose and present a multi-select menu of candidate work products, execute the user's selections, then write the weekly summary note. Two checkpoints in the middle (focus picker, work-product curation); everything else runs autonomously.

**Vault resolution** — at the top of the run, determine which vault is active:

```bash
obsidian vaults
```

- If `ObsidianPersonal` appears, set `$VAULT=ObsidianPersonal` — this is the **personal vault** mode (Life Domains scoring, Domain Gaps section apply).
- Otherwise (e.g. `ObsidianWork`), set `$VAULT` to that vault name — this is **non-personal vault** mode (skip Life Domains lookup, skip Domain Gaps section). Avoidance Radar and agent-context still apply if those files exist.

All `vault=ObsidianPersonal` references below should be read as `vault=$VAULT` — substitute the resolved vault name throughout. Sections marked **[personal-vault only]** are skipped in non-personal mode.

Key rules:
- Vault parameter comes immediately after the subcommand: `obsidian <subcommand> vault=$VAULT [options]`
- Use `path=` for exact vault-relative paths; `file=` for wikilink-style name resolution
- Never run `obsidian --help` — it hangs and never exits

---

## Phase 1 — Survey

Calculate the date range using **daily-note filenames as the source of truth**, not the run date. This way, an overly late run (multi-week backlog) still produces an accurate weekly summary anchored to the actual notes — rather than drifting to "this past Sunday" relative to today.

Produce **two** week numbers:
- `$WEEK_NUM` — the past week being summarized (retrospective lands here).
- `$NEXT_WEEK_NUM` — the ISO week immediately following. The forward-looking `## Weekly Focus` and `## Decisions Needed` land here, because `start-day` reads `4_Archive/Weekly Notes/$(date +%Y-%V).md` — i.e. the *current* week. If we wrote focus into the past-week file, start-day would never see it.

```bash
# Latest YYYY-MM-DD daily note across inbox + archive (cross-platform — via Obsidian API)
LATEST_DATE=$(obsidian eval vault=$VAULT code="
const re = /(\d{4})-(\d{2})-(\d{2})\.md\$/;
const dates = app.vault.getFiles()
  .filter(f => f.path.startsWith('0_Inbox/') || f.path.startsWith('4_Archive/Daily Notes/'))
  .map(f => { const m = f.path.match(re); return m ? \`\${m[1]}-\${m[2]}-\${m[3]}\` : null; })
  .filter(Boolean)
  .sort();
dates[dates.length - 1] || '';
" | sed 's/^=> //; s/^"//; s/"$//')

read WEEK_END WEEK_START WEEK_NUM NEXT_WEEK_NUM < <(python3 -c "
import datetime
latest = datetime.date.fromisoformat('$LATEST_DATE')
today = datetime.date.today()
days_to_sunday = (6 - latest.weekday()) % 7   # weekday(): Mon=0..Sun=6
week_end = latest + datetime.timedelta(days=days_to_sunday)
if week_end > today:                           # week not yet complete; back up one
    week_end -= datetime.timedelta(days=7)
week_start = week_end - datetime.timedelta(days=6)
next_start = week_end + datetime.timedelta(days=1)
print(week_end, week_start, week_end.strftime('%Y-%V'), next_start.strftime('%Y-%V'))
")
echo "Past week: $WEEK_NUM ($WEEK_START to $WEEK_END) | Upcoming: $NEXT_WEEK_NUM | Run date: $(date +%Y-%m-%d)"
```

This handles late runs accurately: the past week reflects the most recent *completed* week of daily notes, and the upcoming-week file gets the focus that start-day will surface.

Read all context before doing any analysis. Run these in sequence:

```bash
# Vault-scope agent context — global frame (Life Domains in personal vault, Avoidance Radar, etc.)
# Returns every file with `agent-context: vault` in frontmatter; read each.
obsidian vault=$VAULT search query="[agent-context:vault]" format=json

# List archived daily notes — filter to past 7 days by filename
obsidian files vault=$VAULT folder="4_Archive/Daily Notes"

# Project velocity — prefer authoritative `last-touched` frontmatter, fall back to canonical-file mtime.
# `last-touched` is written by /snapshot and /log. Files without it haven't had a session-skill
# run yet — fall back to mtime via the Obsidian API (cross-platform — no GNU `find -printf`).
# Canonical file convention: `1_Projects/<Foo>/<Foo>.md` (folder-named note; legacy `Index.md` no longer used).
obsidian vault=$VAULT search query="[last-touched]" format=json
obsidian eval vault=$VAULT code="JSON.stringify(app.vault.getFiles().filter(f => f.path.startsWith('1_Projects/') && f.parent && f.basename === f.parent.name).map(f => ({path: f.path, mtime: f.stat.mtime})).sort((a,b) => a.mtime - b.mtime))"

# Idea stubs waiting for attention
obsidian search vault=$VAULT query="tag:#stub" format=json
```

From the archived daily notes list, filter to files whose YYYY-MM-DD filename falls between WEEK_START and WEEK_END (inclusive). Do not include notes dated after WEEK_END — those belong to the next week's run. Read the `## Distillation` section of each — specifically the "Day in brief" sentence and the **Action items** list. Skip notes with no Distillation section (empty days).

If fewer than 2 daily notes exist in the 7-day window, note this as a low-data week — proceed with what's available, don't abort.

Read each project's canonical file (`1_Projects/<Foo>/<Foo>.md` — the folder-named note):

```bash
obsidian read vault=$VAULT path="1_Projects/<project>/<project>.md"
```

Do this for every project listed under `1_Projects/`. These canonical files typically carry `agent-context: project` and describe each project's current state.

**Internal picture to build (not written yet):**
- Which domains were active in the week's distillations vs. absent
- Which projects had vault activity vs. went silent
- What's accumulating on the Avoidance Radar and for how long
- What idea stubs exist and what projects they relate to (judge by content, not formal links)
- Any `## Feedback` sections on existing notes in project folders (scan while reading)

**Stale agent-context check.** While reading agent-context files in this phase, capture each file's `last-reviewed` frontmatter date (or note its absence). Any file with `last-reviewed` 60+ days ago, or missing the field entirely, is a candidate to surface in `## Stale Context` in the weekly note (Phase 4). Do not edit these files in this skill — the user runs `/refresh-context` for that.

---

## Phase 2 — Score, Diagnose, Curate

This phase has four sub-steps: score every project, capture the week's high-level focus, do lightweight diagnosis on the top candidates and propose work products for each, then present them to the user as a multi-select menu.

### Phase 2a — Score all projects

Score each project against four signals. Higher score = stronger case to focus here this week.

| Signal | How to score |
|--------|-------------|
| **Strategic priority** | **[personal-vault only]** Read from Life Domains — use each project's described priority/cadence as the weight. **In non-personal mode**, weight by the canonical file's frontmatter `status:` value instead (active/in-progress > planning > investigation > idea), defaulting to medium when absent. Idea stubs rank below active projects unless flagged otherwise. |
| **Neglect duration** | Prefer the canonical file's `last-touched` frontmatter (authoritative — written by `/snapshot` and `/log`). Fall back to the mtime from the `obsidian eval` block in Phase 1 if `last-touched` is absent. More days since last touch = higher score. A project touched yesterday scores 0 here. |
| **Idea stubs waiting** | Count stubs from `0_Inbox` whose content is semantically about this project. Each related stub adds to the score. |
| **Phase readiness** | Can useful work happen right now without the user present? A project waiting on an external reply scores low. A project with clear gaps in documentation or strategy scores high. |

**Archive flag check:** If `last-touched` (or mtime fallback) is 60+ days ago AND its canonical file gives no signal of intentional pause, flag it as "is this still active?" rather than scoring it. Do not propose work products for archive-candidate projects — surface the question in the weekly output note instead.

**Feedback check:** If any project's notes contain a `## Feedback` section with content saying "shelving" or "not active" or similar, exclude it from scoring.

Take the **top 3-4 scoring projects** as candidates. The remainder are excluded from this week's depth-dive options.

### Phase 2b — Weekly focus

A single high-level focus sentence steers the rest of the week. It shapes which work products get proposed in the next sub-phase, gets written to the weekly note, and gets surfaced in every daily note via the `start-day` skill. Without this, daily work tends to drift toward small-but-easy tasks at the expense of the bigger picture.

Draft 3 focus angles — one per top-scoring project from Phase 2a (skip the 4th if there were 4 candidates). Each angle is a concrete sentence describing the most valuable direction for that project this week, informed by its canonical file, recent feedback, and current diagnosis. Aim for sentences that would meaningfully inform a Tuesday morning's decision about what to work on.

Present them via `AskUserQuestion` (single-select). The user can pick one or use the automatic "Other" option to write their own. The question itself should be brief — the options carry the framing.

Example shape (illustrative — actual sentences are project-specific):

```
Question: "What's your focus for this week?"
options:
  - label: "Push [top-scoring project] from one phase to the next"
    description: "One-sentence framing of the most valuable next phase shift for this project."
  - label: "Drive [second project] toward its primary near-term metric"
    description: "Concrete weekly target tied to the project's current bottleneck."
  - label: "Triage and pick a direction across pending idea stubs"
    description: "Use when no single project is clearly the focus — consolidate stubs and decide what graduates."
```

Store the chosen sentence as **WEEKLY_FOCUS**. If the user selects "Other", their typed text is the focus. If they decline to choose anything, WEEKLY_FOCUS is empty — proceed without one.

### Phase 2c — Lightweight diagnosis + propose work products per candidate

For each top-candidate project, do a focused diagnosis (faster than the original Phase 3 deep read — just enough to propose work):

1. Recall the canonical file already read in Phase 1
2. Read any notes with `agent-context: project` in the project folder:
   ```bash
   obsidian search vault=$VAULT path="1_Projects/<candidate>" query="[agent-context:project]" format=json
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

When generating multiple options for one project, make them **distinct angles** — not the same work product reworded. E.g. one option might synthesize the work already done into a structured next-step plan, while a second researches external playbooks or comparables — both valid, different focus.

**Use feedback as a hard constraint.** If a project's notes say "prioritize warm network over cold names," do not propose a cold-name work product. The feedback section is authoritative.

**Use the weekly focus as a constraint.** If WEEKLY_FOCUS is set, bias proposals toward work products that advance that focus. Work products for the focus's project should directly serve the focus sentence; work products for other candidate projects should still be coherent with the focus (e.g. don't propose a heavy deep-dive on a non-focus project that would crowd out focus work). If WEEKLY_FOCUS is empty, proceed without this filter.

### Phase 2d — Multi-select checkpoint

Present the candidate work products as a single multi-select question. Group options under per-project headers. Cap at 6-7 total candidates. If WEEKLY_FOCUS is set, surface focus-aligned options first.

Use `AskUserQuestion` with `multiSelect: true`. Each option's `label` is the work product name (concise, 5-8 words); each `description` is one sentence describing what would be produced and why it's valuable now. The question header should reference the project; the question body should be brief.

Example shape (illustrative — actual content driven by Phase 2b):

```
Question: "Which deep dives should I do this week?"
multiSelect: true
options:
  - label: "[Project A]: synthesize this week's discovery into next steps"
    description: "Consolidate recent discovery notes; propose the next 3-5 questions or actions, constrained by stated feedback."
  - label: "[Project A]: decision brief on an open commitment"
    description: "Frame an outstanding go/no-go (travel, spend, scope) as options + tradeoffs. Resolves a blocking decision."
  - label: "[Project B]: research traction tactics from comparable products"
    description: "Pull 4-5 early-stage growth playbooks; draft a lightweight weekly promotion plan."
  - label: "Idea stub consolidation"
    description: "Merge a cluster of related stubs in 0_Inbox into a structured next-step note for the parent project."
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
   obsidian create vault=$VAULT path="1_Projects/<project>/<Descriptive Title>.md" content="---\ntags:\n  - agent-work\ncreated: YYYY-MM-DD\n---\n\n[content]\n\n## Feedback\n" silent
   ```

   Every skill-produced note gets:
   - `tags: agent-work` in frontmatter
   - An empty `## Feedback` section at the bottom

5. **Update the project's canonical file** (`1_Projects/<project>/<project>.md`):

   ```bash
   obsidian append vault=$VAULT path="1_Projects/<project>/<project>.md" content="\n---\n\n**Last worked: YYYY-MM-DD** (via /end-week) — [one sentence describing what was produced]"
   ```

If the same project has multiple selected work products, append one canonical-file update per work product (don't batch).

---

## Phase 4 — Weekly Output Notes (two files)

Write **two** files:

1. **Past-week retrospective** at `4_Archive/Weekly Notes/$WEEK_NUM.md` — what happened, work produced, gaps. This is the historical record.
2. **Upcoming-week forward plan** at `4_Archive/Weekly Notes/$NEXT_WEEK_NUM.md` — Weekly Focus + Decisions Needed. This is what `start-day` reads via `$(date +%Y-%V)` to splice into each daily note next week.

The split exists because `start-day` reads the *current* ISO week's file, not the past one. Writing focus into the past-week file would make it invisible.

### File 1 — Past-week retrospective (`$WEEK_NUM.md`)

```bash
obsidian create vault=$VAULT path="4_Archive/Weekly Notes/$WEEK_NUM.md" content="[retrospective content]" silent
```

Structure:

```markdown
---
tags:
  - weekly-note
week: YYYY-WW
---

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

## Domain Gaps **[personal-vault only]**

Domains from Life Domains with zero activity in the week's daily notes:
- [Domain name] — no mentions in any daily note this week

(Omit this section if all domains had at least some representation. **Omit entirely in non-personal-vault mode** — Life Domains is a personal-vault construct.)

## Archive Candidates

Projects not touched in 60+ days with no clear pause signal:
- [[Project Name]] — last activity: YYYY-MM-DD. Still active?

(Omit if no candidates.)

## Stale Context

Agent-context files (vault/project/area scope) with `last-reviewed` 60+ days old or missing. These shape automatic agent framing — drift here misdirects everything downstream. Run `/refresh-context` to walk through them.

- [[File path]] — last-reviewed: YYYY-MM-DD (or "never")

(Omit if all agent-context files are within 60 days.)

## See also

- Forward plan for the upcoming week: [[$NEXT_WEEK_NUM]]
```

### File 2 — Upcoming-week forward plan (`$NEXT_WEEK_NUM.md`)

**Check first** whether the file already exists:

```bash
obsidian read vault=$VAULT path="4_Archive/Weekly Notes/$NEXT_WEEK_NUM.md"
```

- **If it does not exist:** create it from scratch with the structure below.
- **If it already exists** (e.g. multi-week backlog catch-up, or a prior stub): preserve everything outside the two managed sections. Replace just the contents of `## Weekly Focus` and `## Decisions Needed` (or append them if absent). Use direct file editing via VAULT_PATH for in-place section replacement if needed — do not blindly overwrite the whole file.

Structure for the fresh-create case:

```markdown
---
tags:
  - weekly-note
week: YYYY-WW
---

## Weekly Focus

[WEEKLY_FOCUS sentence — verbatim from Phase 2b]

(Omit this section if WEEKLY_FOCUS is empty. Keep it as a single line — `start-day` reads it and substitutes it into each daily note.)

## Decisions Needed

Questions requiring your input before next week's work can continue:

1. [Specific decision with enough context to answer it]

(Omit this section if no decisions surfaced. To resolve a decision, edit it in place — strikethrough or add **Decided:** inline. start-day reads this section as ambient context.)

## See also

- Retrospective for the past week: [[$WEEK_NUM]]
```

Both files share the same `tags: weekly-note` and `week: YYYY-WW` frontmatter, with the week value matching the filename.

---

## Done

The weekly note and work products are in place. No further output needed.
