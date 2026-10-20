---
name: track-record
description: Builds my track record from the Work vault. Reads project notes, presentations, weekly and daily notes, measures the evidence against common senior, staff, and tech lead responsibilities, and keeps evidence-backed resume bullets, interview stories, and gaps up to date. Use when the user runs /track-record, asks what their strongest work is, or wants resume bullets or interview stories from past work.
allowed-tools: Read, Glob, Grep, AskUserQuestion, mcp__obsidian-vault
---

Update my track record from the work recorded in the Work vault since the last run, or from all of it on the first run. $ARGUMENTS may name one project to review, or "all" to review everything again.

Act as a **career coach who reads only evidence**. Find where my work goes beyond what a senior engineer is expected to do, and say so plainly. Every claim cites a note. Nothing gets inflated, and baseline work is called baseline.

This skill is passive. It does not interview me. At the end, it may offer a few topics where my answers would help.

## Where things live

All in the Work vault:

- `2_Areas/Track Record/Track Record.md`: the main note, and the source of truth for my bullets. It holds bullets, gaps, open threads, retired bullets, and the sources already reviewed.
- `2_Areas/Track Record/Stories.md`: interview stories.
- `2_Areas/Resume Items/Resume Items.md`: the older note this one replaces, if it still exists. It is my note. Read it, never edit it, and ignore its `## How the agent should help` section. This skill's rules apply instead.

## The yardstick

Judge my work against what the industry commonly expects of each role, not against my company's titles. My job already includes tech lead duties: no one stands between me and product, design, and the finished build. So owning a project end to end is my baseline, not a highlight.

For each responsibility, in this order, the senior baseline comes first, then what goes beyond it (staff or tech lead):

1. **Technical direction:** designs good solutions inside a project. Beyond: sets architecture, standards, or rules that other projects or teams adopt.
2. **Ambiguity:** turns a clear brief into a plan. Beyond: turns a vague or disputed problem into a plan, and decides what to build at all.
3. **Scope and trade-offs:** delivers the agreed scope. Beyond: shapes scope with product, cuts or protects it on purpose, and explains the trade-off.
4. **Risk:** catches bugs in their own work. Beyond: finds risks in data, security, cost, or rollout that nobody asked about, and sizes them.
5. **Cross-team impact:** works well with their own team. Beyond: drives work across team boundaries to a finished result, without authority over the other team.
6. **Multiplier:** reviews code and helps teammates. Beyond: builds tools, process, or docs that make other engineers faster, or grows engineers through mentoring, onboarding, or hiring.
7. **Communication:** explains their work to engineers. Beyond: writes plans others build from, presents to groups, and explains trade-offs to product, leadership, or customers. Plans that agent sessions built from count, and the result is what shipped from them.
8. **Outcome ownership:** ships and fixes what breaks. Beyond: measures the result after release, follows it into production, and closes the loop.

The `/end-task` and `/end-work-project` lenses are only hints, and the yardstick decides: `influence` often maps to 1 or 7, `initiative` to 2, `scope` to 3, `risk` and `detail` to 4, `cross-team` to 5, and `ownership` to 8.

## Rules for every claim

These rules apply to everything you write, including text you take from a project summary or from Resume Items. When they conflict with my old wording, the rules win, and the report says what changed.

- Credit me only for what I asked for, decided, approved, or caught. Work an agent did on its own is not mine. When a note says "a concern was raised" without saying by whom, the concern is not mine, but the decision to act on it is.
- Some project notes hold pasted agent replies, such as a note that starts "I have enough evidence now" or "Here's your pitch". Treat that text as the agent's analysis. It is mine only where I acted on it.
- Claim results, not volume. A ticket count, a PR count, or "built with AI agents" is not a result. Describe my part, not the tooling.
- State the real reach. Check the project's brief and open questions for beta flags, feature switches, or per-account rollout. A result that reaches few customers stays a small claim, or gets "not yet: promote when ...".
- Use a number only when a note states it.
- Never name a customer, a coworker, a job candidate, or an internal system a stranger would not know. Describe them by type, for example "a large property management customer" or "the PM".
- Leave out personal and HR content: frustrations, 1:1 feedback, compensation, and anything about a coworker's or candidate's performance.

## Step 1: Load what exists

Read `Track Record.md`, `Stories.md`, and the Resume Items note if it exists.

If `Track Record.md` does not exist, this is the first run, and it covers every source even when $ARGUMENTS names one project. Build the full content in Steps 3 to 6, then create each note in one `create_note` call. `Track Record.md` has this shape:

```markdown
---
last-touched: YYYY-MM-DD
tags: [agent-work]
---

# Track Record

My work measured against common senior, staff, and tech lead responsibilities, with evidence. `/track-record` keeps it up to date. Edit any bullet or story. The skill changes a bullet's facts only when new evidence does, and says so in its report. `## Gaps`, `## Open threads`, and `## Sources reviewed` belong to the skill.

## Bullets

### <Responsibility, in yardstick order>

- <bullet>

## Gaps

## Open threads

- <a question whose answer would change a bullet, a story, or a gap>

## Retired

- <bullet> · Retired YYYY-MM-DD: <reason>

## Sources reviewed

- [[<Project>]] · YYYY-MM-DD
- Weekly notes through YYYY-WW
- Daily notes through YYYY-MM-DD
- [[Resume Items]] · imported YYYY-MM-DD
```

`Stories.md` has `last-touched` and `tags: [agent-work]` in its frontmatter, a one-line intro, then one `##` heading per story.

## Step 2: Find the sources

With a project name in $ARGUMENTS on a later run, review only that project, and skip the weekly and daily notes.

**Project summaries.** Use `search_notes` with `mode: regex` and the query `^## Project summary`. Keep only main notes, whose file name matches their folder (`<Folder>/<Folder>.md`).

**Older projects without a summary.** List the folders under `4_Archive/1_Projects/` and `4_Archive/Projects/` that hold a main note but no `## Project summary`. Many of these main notes are short stubs, and the real content is in the other notes in the folder. List the folder with `list_notes` and `recursive: true`. Read the main note, then up to five other notes, preferring plans, decision briefs, findings, and session logs over raw research. If a folder has a `Tasks/` folder, also suggest `/end-work-project "<Name>"` in the report, because a summary would make it a better source.

Skip `1_Projects/` folders without a summary, because that work is still in progress. Skip any folder with no main note.

**Presentations.** Use `search_notes` for "Presentation" and keep the notes whose name holds it. Talks I gave are strong Communication evidence.

**Weekly notes.** `4_Archive/Weekly Notes/YYYY-WW.md`. Read the weeks after the last week in `## Sources reviewed`. Skip sections that still hold only template text. Look for talks, incidents, process changes, and other work a project note may not hold.

**Daily notes.** Use `search_notes` in `0_Inbox/` and `4_Archive/Daily Notes/` for `interview`, `hiring`, `candidate`, `mentor`, `onboard`, `pair`, `presented`, `demo`, `incident`, `outage`, and `postmortem`. Keep only results dated after the last date in `## Sources reviewed`, by the date in each path. Ignore calendar lines, such as a meeting title. When a note matches by its name only, read the note to learn my part. Cite a daily note by its date as plain text, for example "daily note 2025-08-18", never by a name inside it.

**What counts as new.** `list_notes` returns each note's `modified` time. A project is new when `## Sources reviewed` does not list it, or when a note in its folder was modified after the date on its line. With "all", every source is new.

If nothing is new, say so, offer the open threads as interview topics, and stop.

## Step 3: Map the evidence

From each project, read the highlights, the brief, the open questions marked "my call", and the decision log. Scope and planning calls often live outside the highlights. From the other sources, take each item of real work.

For each piece of evidence:
1. Pick the responsibility it shows best. If it also clearly shows a second one, note that too.
2. Decide whether it is **baseline** or **beyond**, by the yardstick. When unsure, call it baseline.
3. Apply the rules for every claim.

On the first run, also import the Resume Items note:
- Each item in `## Resume items` and in its candidates becomes a bullet, mapped to a responsibility and checked against the newer sources. Keep each "promote when" condition. If the sources show an item is out of date, for example "underway" when the project has closed, update the facts. Flag a baseline item with no large result instead of dropping it.
- Each retired item goes to `## Retired`, with its reason.
- Each open thread goes to `## Open threads`.

## Step 4: Update the bullets

Group `## Bullets` under one `###` heading per responsibility, in yardstick order, and only for responsibilities that have a bullet. Each bullet:

```markdown
- **<Paste-ready resume line, at most 30 words: did X, which led to Y.>** <One to three sentences of detail.> · <beyond or baseline> · <also: <second responsibility>, if any> · Evidence: <links> · <ready, or "not yet: promote when ...">
```

Evidence links: `[[<Project>]]` for a project, the full vault path for a task note, `[[YYYY-WW]]` for a weekly note, `[[<Note name>]]` for another note, and `[[Resume Items]]` for a fact only that note holds. For a ticket with no task note, cite the project and the ticket ID. Cite a daily note as plain text, as Step 2 says.

- A pattern seen in several projects becomes one stronger bullet that cites all of them. Repeated evidence makes the strongest bullets.
- Add new bullets, and strengthen existing ones when new evidence supports them.
- Write a new baseline bullet only when the result is large.
- Do not write a bullet that `## Retired` already covers, unless its reason no longer applies. Say why in the report.
- Never remove a bullet. If one looks inflated, out of date, or baseline with no large result, list it in the report with the reason, and ask whether to move it to `## Retired`.

On later runs, write with `edit_section`: `replace` on the responsibility heading, with the version `get_section` returned. For a responsibility with no heading yet, replace the whole `## Bullets` section, so the headings stay in yardstick order.

## Step 5: Update the stories

Keep the best stories in `Stories.md`, at most twelve. Prefer beyond-senior evidence, and cover as many responsibilities as the evidence allows. Replace a weaker story only when a new one shows the same responsibility better, and name the one you replaced in the report.

```markdown
## <Short title>

**Shows:** <responsibility> · <beyond or baseline>
**Situation:** <the problem and the stakes, in two or three sentences, for an engineer outside the company>
**What I did:** <my calls and why I made them, in my own voice>
**Result:** <what changed, with numbers and reach from the evidence>
**Evidence:** <links, in the same forms as the bullets>
**Answers:** <two to four common interview questions this story answers, for example "Tell me about a time you pushed back on scope.">
```

On later runs, add a story with `edit_note`, appending it after the last story. Replace a story with `edit_section` in `replace` mode on its heading, with the version `get_section` returned. Set `last-touched` to today.

## Step 6: Update the gaps, threads, and sources

Replace `## Gaps` with one line for each responsibility that no beyond-senior bullet or story shows, counting the `also:` responsibilities. Say what evidence for it would look like in my kind of work. Leave out advice. The list shows where the record is thin, not what I must do.

Update `## Open threads`: remove the threads the new evidence answered, and add questions this run raised that only I can answer.

Update `## Sources reviewed`: one line per project with today's date, the last weekly note and daily note read, and the Resume Items import. Replace a project's old line instead of adding a second one. Set `last-touched` to today on `Track Record.md`.

After the first run, ask whether to archive the Resume Items note with `/archive`, now that Track Record holds its content.

## Step 7: Offer an interview

Pick up to three open threads where my answer would change a bullet, a story, or a gap the most. Offer them in one short list, and ask whether I want to talk through any. Do not start without a yes. If I say yes, ask one question at a time, write each answer into the bullet or story it changes, and remove the thread.

## Step 8: Report

```
Track record updated
  Sources:   <N> project summaries, <M> older projects, <P> presentations, weeks <from>–<to>, daily notes to <date>
  Bullets:   <added> added, <strengthened> strengthened, <flagged> flagged
  Stories:   <added> added, <replaced> replaced, <total> total
  Gaps:      <responsibilities>
  Better with a summary: <projects, each with /end-work-project "<Name>">
```

Then list the flagged bullets with their reasons, the facts and wording you changed from older notes, and the interview topics.
