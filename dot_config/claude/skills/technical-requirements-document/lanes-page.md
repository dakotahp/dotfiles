# Lanes page

A private artifact page that shows which tickets can start now, which wait, and on what. It keeps showing this as statuses change. A reader answers "what can start right now?" in a few seconds, without reading the TRD.

Build it only for a project with 3 or more tickets.

## The template

`lanes-template.html` in this skill's directory is the whole page. Copy it to your scratchpad directory (or `$TMPDIR`) as `<slug>-lanes.html` and change only the `CONFIG`, `TICKETS` and `ORDER` blocks at the top of the script. Do not restyle it.

### `CONFIG`

- `eyebrow`: project ID, ticket count, and the service or surface, e.g. `"PROJ-12 · 9 tickets · Public API"`.
- `title`: the project's own name. Also set the page's `<title>` to `<name> Lanes`.
- `intro`: keep the default. Add one sentence if some tickets wait for a deploy or an external ticket.
- `links`: the TRD, the technical plan, and the tracker project, as `{ label, href }`.
- `issueUrl`: the tracker's issue URL prefix, taken from a real ticket URL, e.g. `https://linear.app/<workspace>/issue/`.
- `asOf`: today's date, e.g. `"4 Nov 2026"`.
- `notes`: two short lines. What the blue tag means for this project, and that ticket numbers match the TRD.
- `waves`: leave `null`. The page names the waves from the graph.

### `TICKETS`

One entry per TRD ticket: `{ n, id, title, kind, needs }`.

- `n` is the TRD ticket number, so the page and the TRD use the same numbers. Ticket 0 is the contract ticket.
- `id` is the tracker ID.
- `title` is a short form of the TRD title, under about 60 characters.
- `kind` is the layer or role: `foundation`, `refactor`, `frontend`, `docs`, `qa`, or `customer-facing`. Only `customer-facing` gets the accent color. Use it only for the tickets that deliver what the customer asked for.
- `needs` lists the **direct** dependencies only, as TRD numbers. It must match the tracker's "blocked by" relations exactly.
- `afterDeploy: true` on a ticket that waits for its needs to be deployed, not just to have open PRs.
- `status` is optional. Set it to the tracker's current state, so the first frame is correct before live statuses load.

An external prerequisite from another project gets `external: true`, `kind: "external"`, and an unused number above the TRD's tickets, e.g. `90`. It draws dashed, is left out of the counts, and counts as met only when Done, because it must merge.

### `ORDER`

The vertical order of cards, read top to bottom within each column. It is the only hand-tuned part. Put connected tickets near each other so the curves cross as little as possible. A ticket missing from `ORDER` goes to the bottom of its column.

## Rules the page applies

- A ticket's wave is its depth: 0 with no needs, otherwise 1 + the deepest need. Columns always match the real graph.
- **Ready** means the ticket is Not started and every ticket it needs is In Review or Done. That mirrors the TRD's rule that work stacks on an open PR. With `afterDeploy`, or for an external need, the need must be Done.
- Statuses are `Not started`, `In Progress`, `In Review` and `Done`. Map the tracker's states onto these four.

## Publish and seed

1. Load the `artifact-capabilities` skill. Publish the file with the Artifact tool, `icon: "map"`, and `capabilities: { db: { rules: [{ path: "", read: "view", write: "owner" }] } }`. Everyone who can open the page reads statuses. Only the owner writes them.
2. Seed collection `tickets` with one `ArtifactData` batch: one document per ticket, id = tracker ID, body `{ status, updated_at, pr_url? }`. `updated_at` is an ISO timestamp.
3. Record the page URL. With a vault folder, set `lanes-page:` in the vault main file's frontmatter. Also add a `**Lanes page:** <url>` line to the TRD header, in the Linear document and the draft.

## Keep it current

Change one `tickets` document per status change, with `ArtifactData`. Never republish to change a status. Republish only when the ticket set or the dependencies change. Then update `TICKETS` and `ORDER` in the same file and publish to the same URL.
