---
name: end-week
description: Use at the end of the week to review vault activity, set a weekly focus, curate deep-dive work products, and write the weekly summary note.
allowed-tools: Bash, Read, Edit, Write, WebSearch, WebFetch, AskUserQuestion
model: claude-opus-4-7
---

Weekly review session. Works through four phases: survey the week, score top-candidate projects + capture a weekly focus + diagnose and present a multi-select menu of candidate work products + review idea fragments for development, execute the user's selections, then write the weekly summary note. Three checkpoints in the middle (focus picker, work-product curation, idea fragment triage); everything else runs autonomously.

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
# `last-touched` is written by /update-project-state and /log-project-session. Files without it haven't had a session-skill
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
| **Neglect duration** | Prefer the canonical file's `last-touched` frontmatter (authoritative — written by `/update-project-state` and `/log-project-session`). Fall back to the mtime from the `obsidian eval` block in Phase 1 if `last-touched` is absent. More days since last touch = higher score. A project touched yesterday scores 0 here. |
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
- **One or more selected:** proceed to Phase 2e, then Phase 3, looping over each selected work product
- **Zero selected:** proceed to Phase 2e; if nothing is selected there either, skip Phase 3 entirely and go straight to Phase 4. The weekly summary still gets written; `## Work Produced` shows "None — by user choice."

### Phase 2e — Idea Fragment Review

This phase runs after Phase 2d regardless of whether any work products were selected. It gives every idea fragment a chance to be developed before the session ends.

**If no stubs were found in Phase 1, skip this phase entirely.**

**Read stub contents.** For each stub path returned by the Phase 1 search, read the file to get full content. Extract from each:
- Title: the `<Short Title>` portion of the filename `Idea - <Short Title>.md`
- Teaser: first non-frontmatter, non-blank line of the body
- Source date: value of the `source:` frontmatter field (e.g. `[[2026-05-14]]` → `2026-05-14`)

**Cap at 4.** If more than 4 stubs exist, select the 4 with the most recent source dates. Note the count of remaining stubs in your response after the question resolves — they are not lost, just deferred to a future session.

**Present the multi-select.** Use `AskUserQuestion` with `multiSelect: true`:

```
Question: "Which idea fragments do you want to develop this session?"
multiSelect: true
options:
  - label: "<Short Title>"
    description: "<Teaser> (captured <source date>)"
  # … up to 4 stubs
```

If the user selects none, skip the per-stub direction questions and proceed directly to Phase 3. There is nothing to execute for stubs.

**Per selected stub — direction picker.** For each selected stub (sequentially, not in parallel — each answer informs the next question if needed):

1. Re-read the stub content (already in memory)
2. Analyze the idea. Generate exactly **3 development directions** that are specific to this idea's content — not generic category labels. Each direction should describe a concrete output and why it's the right next move for this particular idea. Use these direction shapes as guides (pick the 3 most applicable):

   | Direction shape | When to use |
   |---|---|
   | Flesh out the concept structure | Idea is promising but underdeveloped — needs scaffolding before any action |
   | Research comparables or prior art | Idea's viability depends on what already exists — external grounding needed |
   | Map and connect to an existing project | Idea clearly belongs to an active project; output is a note in that project's folder |
   | Draft a project proposal with scope | Idea is concrete enough to stand alone as a project — needs a framing note |
   | Generate scoping questions | Idea is genuinely open-ended; the right next step is clarifying what it even means |
   | Write up as a reference resource | Idea is a concept worth knowing, not an action — belongs in `3_Resources/` |

3. Present via `AskUserQuestion` (single-select, 3 options). Labels should be concrete and idea-specific. The automatic "Other" option covers ad-hoc prompts.

   Example shape (illustrative — actual labels are idea-specific):
   ```
   Question: "How should I develop '<Idea Title>'?"
   options:
     - label: "Flesh out the core structure with current context"
       description: "Expand using recent notes and project state as source material."
     - label: "Research comparable approaches or prior art"
       description: "Find 3-4 real examples; identify what makes each useful; adapt to your context."
     - label: "Design it as a recurring practice, not a one-time exercise"
       description: "Frame it as an ongoing area under 2_Areas — with a cadence and update convention."
   ```

4. Store `(stub_path, direction_or_prompt)` for execution in Phase 3c. If the user selects "Other" and types a prompt, use that verbatim as the direction.

---

## Phase 3 — Execute Selected Work Products and Idea Fragments

For each selected item (work products from Phase 2d, then idea fragments from Phase 2e), execute sequentially. Work products first, then stubs.

### Phase 3a — Per work product

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

### Phase 3b — Per project (after all work products for that project are created)

After every work product for a single project has been written, do **one** session-log write and **one** `last-touched` stamp for that project. Replaces an earlier pattern that appended `**Last worked:**` footers directly onto the canonical file — those bloated the canonical file with event history that belongs in session logs.

5. **Write the per-project session log:**

   One log per project per end-week run, covering every work product produced for that project this week. Mirrors the structure that `/log-project-session` writes (Quick Reference, Decisions Made, Files Modified, Pending Tasks, Quick Resume Context), assembled automatically from what end-week just did — no AskUserQuestion prompts.

   ```bash
   LOG_TIMESTAMP=$(date +%Y-%m-%d-%H_%M)
   LOG_FILENAME="${LOG_TIMESTAMP}-end-week-${WEEK_NUM}.md"
   ```

   Compose the log content using this template (substitute placeholders):

   ```markdown
   # Session Log: YYYY-MM-DD HH:MM - End Week ${WEEK_NUM} Review

   ## Quick Reference
   **Keywords:** end-week weekly-review ${WEEK_NUM} <project-slug> <work-product-keywords>
   **Outcome:** <one-sentence summary of what was produced for this project this week>

   ## Decisions Made
   - <decision driving each work product, if any — pulled from Phase 2c diagnosis>

   ## Files Modified
   - `<work product path>`: <one-line description of what it contains and why>
   - (one bullet per work product produced for this project)

   ## Pending Tasks
   - <follow-ups the work product surfaced, if any>

   ## Quick Resume Context
   <2-3 sentences a future session would want: which work products landed this week, which diagnosis they came from, and what they leave the project ready to do next>
   ```

   Save it:

   ```bash
   obsidian create path="1_Projects/<project>/Session Logs/${LOG_FILENAME}" vault=$VAULT content="<full log content>" silent
   ```

   The `obsidian create` command creates the `Session Logs/` folder if it doesn't exist.

6. **Stamp `last-touched` on the canonical file** (atomic read → modify-frontmatter → write-back; mirrors `/log-project-session` Step 7.25). **Never use `obsidian property:set`** — it destroys the file body on success.

   ```bash
   # a. Read
   obsidian read path="1_Projects/<project>/<project>.md" vault=$VAULT
   ```

   - b. In memory: if a `---`-delimited frontmatter block exists at top of file, set (or add) `last-touched: YYYY-MM-DD`. If no frontmatter block, prepend one containing only that property. Preserve every other frontmatter key and the entire file body exactly as-is.
   - c. Write back:

   ```bash
   obsidian create path="1_Projects/<project>/<project>.md" vault=$VAULT content="<full reconstructed content>" overwrite silent
   ```

   - d. **Verify the write was not destructive** by reading the file back and confirming the body length matches what was reconstructed. If anything looks wrong, **stop and report to the user** — a truncated canonical file is worse than a missing date stamp.

   Do **not** append `**Last worked:**` footers to the canonical file. Event history belongs in `Session Logs/`.

If the same project has multiple selected work products, still produce **one** session log and **one** `last-touched` stamp per project per end-week run, not one per work product.

### Phase 3c — Idea Fragment Development

For each `(stub_path, direction_or_prompt)` pair from Phase 2e, execute the development work and write back to the stub file. Do them sequentially.

**For each stub:**

1. Re-read the stub content (already in memory; re-read only if needed)
2. Execute the chosen direction — synthesize, draft, research, or map as instructed. Use web research (WebSearch, WebFetch) when the direction calls for external context.
3. **Write the developed content back to the stub file in place:**

   ```bash
   obsidian create vault=$VAULT path="<stub_path>" content="---\ntags:\n  - idea\n  - agent-work\nsource: \"<original source value>\"\n---\n\n[developed content]\n\n## Feedback\n" overwrite silent
   ```

   Key rules for the in-place rewrite:
   - Keep the `idea` tag. Remove the `stub` tag (the idea is no longer a sparse capture).
   - Add `agent-work` tag to mark this as agent-developed content.
   - Preserve the original `source:` frontmatter value.
   - Append an empty `## Feedback` section — this is where the owner steers future development.
   - If the direction was "map to existing project," also create a linked note in that project's folder pointing back to this stub. Do not move the stub itself — routing is the owner's call.
   - If the direction was "draft a project proposal," write the proposal content into the stub (same rules above). The owner decides whether to promote it to a `1_Projects/` folder.

4. **Do NOT write a session log or stamp `last-touched` on any project** for stub development, unless the direction explicitly mapped the stub into a project folder. In that case, include the stub-development note in that project's Phase 3b session log.

5. Add the developed stub to the `<!-- work-produced -->` list in Phase 4 with a one-line description of what was done.

---

## Phase 4 — Weekly Notes (one note per week, two operations per run)

Each ISO week has **one** note at `4_Archive/Weekly Notes/$WEEK_NUM.md`. That note has two halves:

- **Forward half** (`## Weekly Focus`, `## Decisions Needed`) — written *before* the week starts, by the prior week's `end-week` run. `start-day` during the week reads `## Weekly Focus` and splices it into each daily note.
- **Retrospective half** (`## Projects Focused`, `## Work Produced`, `## Not Selected This Week`, `## Week in Brief`, `## Domain Gaps`, `## Archive Candidates`, `## Stale Context`) — filled in *after* the week ends, by that week's `end-week` run.

So a single end-week run does two writes to two different week files:

1. **Amend `$WEEK_NUM.md`** (past week — already stubbed last week) — fill in the retrospective sections. Preserve the forward half that was set last week.
2. **Stub `$NEXT_WEEK_NUM.md`** (upcoming week) — write the forward sections for the coming week. Retrospective sections remain empty until next end-week.

Both writes use the same template: `3_Resources/Obsidian Templates/Weekly Note Template.md`. Resolve VAULT_PATH:

```bash
VAULT_PATH=$(obsidian eval vault=$VAULT code="app.vault.adapter.basePath" | sed 's/^=> //; s/^"//; s/"$//')
```

### Placeholders in the template

| Placeholder | Set by | Content |
|---|---|---|
| `<!-- week -->` (frontmatter) | both | `$WEEK_NUM` or `$NEXT_WEEK_NUM` matching the file. |
| `<!-- weekly-focus -->` | stub run | Verbatim WEEKLY_FOCUS sentence from Phase 2b. If empty, leave the placeholder unfilled; **start-day** will skip the splice. |
| `<!-- decisions-needed -->` | stub run | Numbered list of forward-looking decisions blocking next week's work. |
| `<!-- projects-focused -->` | amend run | One `**[[Project Name]]** — why it was picked + brief framing` line per project with executed work. |
| `<!-- work-produced -->` | amend run | Bulleted list of `- [[Note title]] — one-sentence description`. Include both project work products (Phase 3a) and developed idea fragments (Phase 3c). If zero in both: `None — by user choice.` |
| `<!-- not-selected -->` | amend run | Candidates surfaced in Phase 2d but not picked. Leave empty if all selected or none generated. |
| `<!-- week-in-brief -->` | amend run | 2-3 sentences synthesizing the week from daily-note distillations. |
| `<!-- domain-gaps -->` | amend run | **[personal-vault only]** Life Domains with zero activity. In non-personal mode, leave empty (or delete the `## Domain Gaps` section entirely if rendering bothers you). |
| `<!-- archive-candidates -->` | amend run | Projects untouched 60+ days, or `None — all active projects have recent activity.` |
| `<!-- stale-context -->` | amend run | Stale agent-context files, or `All agent-context files are within the 60-day window.` |
| `<!-- prev-week -->` | both | ISO week before the file's week. |
| `<!-- next-week -->` | both | ISO week after the file's week. |

### Operation 1 — Amend `$WEEK_NUM.md` (past week retrospective)

Read the file first:

```bash
obsidian read vault=$VAULT path="4_Archive/Weekly Notes/$WEEK_NUM.md"
```

- **If it exists** (normal case — last week's end-week run stubbed it): use Python to replace just the retrospective placeholders (`<!-- projects-focused -->`, `<!-- work-produced -->`, `<!-- not-selected -->`, `<!-- week-in-brief -->`, `<!-- domain-gaps -->`, `<!-- archive-candidates -->`, `<!-- stale-context -->`) in-place. Preserve the forward half and everything else. Operate on `$VAULT_PATH/4_Archive/Weekly Notes/$WEEK_NUM.md` directly.
- **If it does not exist** (bootstrap — first end-week ever, or the prior week's stub was skipped): render the full template fresh with retrospective placeholders filled and forward placeholders left empty (no `Weekly Focus`/`Decisions Needed` were captured for that bygone week).

### Operation 2 — Stub `$NEXT_WEEK_NUM.md` (upcoming week forward plan)

Read the file first:

```bash
obsidian read vault=$VAULT path="4_Archive/Weekly Notes/$NEXT_WEEK_NUM.md"
```

- **If it does not exist** (normal case): render the full template with forward placeholders filled (`<!-- weekly-focus -->`, `<!-- decisions-needed -->`, `<!-- week -->`, `<!-- prev-week -->`, `<!-- next-week -->`). Retrospective placeholders stay as unfilled `<!-- foo -->` markers — they'll be filled at next week's end-week run.
- **If it already exists** (catch-up runs or manual prior creation): replace just the forward-section placeholders in-place. Never overwrite retrospective content that might have been hand-edited.

### Render pattern (Python heredoc, same as start-day Step 2d)

```python
python3 << 'PYEOF'
vault_path = "$VAULT_PATH"
template = f"{vault_path}/3_Resources/Obsidian Templates/Weekly Note Template.md"
out = f"{vault_path}/4_Archive/Weekly Notes/$WEEK_NUM.md"  # or $NEXT_WEEK_NUM.md
with open(template, 'r', encoding='utf-8') as f:
    content = f.read()
# Embed each substitution string directly in the heredoc — do not interpolate from shell,
# the replacement strings may contain characters that break shell quoting.
content = content.replace('<!-- week -->', 'WEEK_NUM_VALUE')
content = content.replace('<!-- weekly-focus -->', 'WEEKLY_FOCUS_VALUE')
# … and so on for each placeholder
with open(out, 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF
```

For the **amend** case (file already exists), read the existing content first, then run the same `.replace()` calls — they'll only replace placeholders that are still present. Forward-half placeholders that were already filled out by the prior week's stub run will be plain text by now, so the amend run's `.replace()` calls for retrospective placeholders won't touch them.

---

## Done

The weekly note and work products are in place. No further output needed.
