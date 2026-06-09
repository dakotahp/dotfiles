---
name: vault-health
description: Vault maintenance skill. Auto-fixes inspiration notes missing a summary: field, then reports dead wikilinks, orphan notes, and suggests tags for under-tagged notes in 1_Projects, 2_Areas, and 3_Resources. Run periodically to keep the vault tidy and discoverable.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

Vault health check. Runs in two phases: auto-fixes first, then a report of suggestions. Present the full output at the end in a single structured summary.

**Vault resolution — run both in parallel at the start:**

```bash
obsidian eval code="app.vault.getName()"
obsidian eval code="app.vault.adapter.basePath"
```

Store as VAULT_NAME and VAULT_PATH. Use `vault=$VAULT_NAME` in all subsequent obsidian CLI commands. All file operations use VAULT_PATH as the absolute base.

---

## Phase 1 — Auto-fixes

### 1a: Inspiration notes missing `summary:`

```bash
obsidian vault=$VAULT_NAME search query="tag:#inspiration" format=json
```

For each returned path, check whether `summary:` appears in the frontmatter (between the opening `---` and the closing `---`). Collect paths where it is absent.

For each note missing `summary:`:

1. Read the file.
2. Generate a 1-sentence declarative insight capturing the note's core idea. Follow the `Vault Conventions ## The summary: Field` guidance: insight not description, lead with a memorable phrase if one exists.
3. Add the field to the frontmatter using Python (the same insertion approach used in prior backfill -- find the closing `---` of the frontmatter block, insert `summary: "..."` on the line before it):

```python
python3 << 'PYEOF'
path = "FULL_PATH"
summary = "GENERATED_SUMMARY"

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

end = content.find('\n---', 3)
if end != -1 and 'summary:' not in content[:end]:
    safe = summary.replace('"', '\\"')
    content = content[:end] + f'\nsummary: "{safe}"' + content[end:]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("fixed")
else:
    print("skipped")
PYEOF
```

Process all missing notes before moving to Phase 2. Track count for the summary output.

---

## Phase 2 — Reports and suggestions

Run all three of the following in parallel (they are independent reads).

### 2a: Dead wikilinks

A dead wikilink is a `[[Target]]` or `[[Target|Alias]]` in any note's body where no file in the vault has a matching name (case-insensitive basename without extension).

**Step 1 — Build the note name index:**

```python
python3 << 'PYEOF'
import os, json

vault = "VAULT_PATH"
names = set()
for root, dirs, files in os.walk(vault):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if f.endswith('.md'):
            names.add(os.path.splitext(f)[0].lower())

print(json.dumps(sorted(names)))
PYEOF
```

**Step 2 — Find all wikilinks and check against the index:**

```python
python3 << 'PYEOF'
import os, re, json

vault = "VAULT_PATH"
note_names = set("""NAME_INDEX""".split())  # inject the lowercased name list

dead = []
for root, dirs, files in os.walk(vault):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if not f.endswith('.md'):
            continue
        path = os.path.join(root, f)
        rel = path[len(vault)+1:]
        try:
            with open(path, 'r', encoding='utf-8') as fh:
                content = fh.read()
            # Strip frontmatter before searching for links
            body = content
            if content.startswith('---'):
                end = content.find('\n---', 3)
                if end != -1:
                    body = content[end+4:]
            for m in re.finditer(r'\[\[([^\]|#]+)', body):
                target = m.group(1).strip()
                if target.lower() not in note_names:
                    dead.append({'file': rel, 'link': target})
        except:
            pass

for d in dead:
    print(f"{d['file']}  →  [[{d['link']}]]")
PYEOF
```

Collect all dead link findings. No auto-fix -- present as report.

### 2b: Orphan notes

An orphan note has no inbound wikilinks from any other note AND no outbound wikilinks in its own body. Exclude: daily notes (`0_Inbox/YYYY-MM-DD.md` pattern), weekly notes (tagged `weekly-note`), the spec/plan files in `0_Inbox/`, and `.stversions/` paths.

```python
python3 << 'PYEOF'
import os, re, json
from collections import defaultdict

vault = "VAULT_PATH"

# Build full map: note name → rel path, and rel path → outbound links
files_map = {}  # rel_path → basename_lower
outbound = {}   # rel_path → set of link targets (lowercased)
inbound = defaultdict(set)  # basename_lower → set of rel_paths that link to it

for root, dirs, files in os.walk(vault):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in files:
        if not f.endswith('.md'):
            continue
        path = os.path.join(root, f)
        rel = path[len(vault)+1:]
        if '.stversions' in rel:
            continue
        basename = os.path.splitext(f)[0].lower()
        files_map[rel] = basename
        try:
            with open(path, 'r', encoding='utf-8') as fh:
                content = fh.read()
            body = content
            if content.startswith('---'):
                end = content.find('\n---', 3)
                if end != -1:
                    body = content[end+4:]
            links = set()
            for m in re.finditer(r'\[\[([^\]|#]+)', body):
                target = m.group(1).strip().lower()
                links.add(target)
                inbound[target].add(rel)
            outbound[rel] = links
        except:
            outbound[rel] = set()

import re as _re
DATE_PAT = _re.compile(r'^\d{4}-\d{2}-\d{2}\.md$')

orphans = []
for rel, basename in files_map.items():
    fname = os.path.basename(rel)
    # Exclusions
    if DATE_PAT.match(fname):
        continue
    if '0_Inbox' in rel and not rel.startswith('0_Inbox/2'):
        pass  # include non-date inbox files in orphan check
    has_outbound = bool(outbound.get(rel))
    has_inbound = bool(inbound.get(basename))
    if not has_outbound and not has_inbound:
        orphans.append(rel)

for o in sorted(orphans):
    print(o)
PYEOF
```

Collect all orphan paths. No auto-fix -- present as report.

### 2c: Tag suggestions

Scan up to **20 files** from `1_Projects/`, `2_Areas/`, and `3_Resources/` that have **2 or fewer existing tags** (not counting `agent-context` files, which are loaded separately). Pick files round-robin across the three folders to avoid always hitting one area.

**Step 1 — Find candidates:**

```python
python3 << 'PYEOF'
import os, re, json

vault = "VAULT_PATH"
folders = ['1_Projects', '2_Areas', '3_Resources']
buckets = {f: [] for f in folders}

for folder in folders:
    base = os.path.join(vault, folder)
    if not os.path.exists(base):
        continue
    for root, dirs, files in os.walk(base):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for f in files:
            if not f.endswith('.md'):
                continue
            path = os.path.join(root, f)
            rel = path[len(vault)+1:]
            try:
                with open(path, 'r', encoding='utf-8') as fh:
                    content = fh.read()
                if not content.startswith('---'):
                    buckets[folder].append({'path': rel, 'tags': []})
                    continue
                end = content.find('\n---', 3)
                if end == -1:
                    continue
                fm = content[3:end]
                # Skip agent-context files
                if 'agent-context:' in fm:
                    continue
                tag_lines = re.findall(r'^\s+- (.+)$', fm, re.MULTILINE)
                buckets[folder].append({'path': rel, 'tags': tag_lines})
            except:
                pass

# Round-robin pick up to 20 with 2 or fewer tags
candidates = []
max_tags = 2
limit = 20
iters = [iter([x for x in buckets[f] if len(x['tags']) <= max_tags]) for f in folders]
while len(candidates) < limit:
    advanced = False
    for it in iters:
        try:
            candidates.append(next(it))
            advanced = True
            if len(candidates) >= limit:
                break
        except StopIteration:
            pass
    if not advanced:
        break

print(json.dumps(candidates))
PYEOF
```

**Step 2 — Fetch the vault's existing tag vocabulary:**

```bash
obsidian vault=$VAULT_NAME tags sort=count
```

Parse the output to extract all tag names (strip counts and `#` prefixes). Store as VAULT_TAGS -- the live vocabulary to draw from when making suggestions.

**Step 3 — For each candidate, read the note and suggest 2-3 tags:**

Read the file content (or just the first 30 lines if it is long). Based on the folder, filename, existing tags, and content, suggest 2-3 tags that:
- Follow vault conventions: singular nouns, kebab-case
- Do not duplicate existing tags on the note
- Prefer tags already present in VAULT_TAGS over coining new ones -- the live vocabulary is the source of truth, not any hardcoded list
- Coin a new tag only when nothing in VAULT_TAGS fits and the content clearly belongs to a distinct category
- Omit suggestions that would just echo the folder name (e.g. don't suggest `project` for a file in `1_Projects`)

Present as suggestions only -- do not write to files.

---

## Phase 3 — Output

Present everything in a single structured report:

```
## Vault Health Report — YYYY-MM-DD

### Auto-fixed
- Inspiration notes missing summary: N fixed (list filenames)
  (or "None needed" if all were already set)

### Dead Wikilinks
(table: File | Broken link target)
(or "None found")

### Orphan Notes
(list of vault-relative paths with no inbound or outbound links)
(or "None found")

### Tag Suggestions
(for each note: path, current tags, suggested tags with one-line rationale)
(note: these are suggestions only — apply manually or ask me to write them)
```

Keep the report skimmable. Use tables where a list would be long. Flag anything that looks like a systematic issue (e.g. "most orphans are in 3_Resources/some-folder -- these may be intentionally standalone reference notes").
