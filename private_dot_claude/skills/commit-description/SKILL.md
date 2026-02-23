---
name: commit-description
description: Generates a commit title and body for the current changes by analyzing the diff and the repo's existing commit style. Pass optional context to guide the output (e.g. ticket number, intent).
allowed-tools: Bash
---

Generate a commit title and body for the current changes. If $ARGUMENTS is provided, treat it as additional context (e.g. a ticket number, a clarification of intent, or the type of change) and factor it into the output.

---

## Step 1 — Read the changes

Run `git diff --staged` to see staged changes. If the output is empty, run `git diff` instead to see unstaged changes. Read the full diff.

---

## Step 2 — Read commit history for style

Run `git log --oneline -20` to understand the conventions this repo uses:
- Does it use conventional commits (`feat:`, `fix:`, `chore:` etc.)?
- Does it reference ticket numbers?
- Are titles sentence case or lowercase?
- Is there a consistent body format?

Match the style of the existing commits.

---

## Step 3 — Check for documented conventions

Check if any of these files exist and mention commit message guidelines:
- `CONTRIBUTING.md`
- `.github/CONTRIBUTING.md`
- `CLAUDE.md`

If guidelines exist, follow them. If they conflict with the observed commit history, prefer the documented guidelines.

---

## Step 4 — Output the commit description

Output the result in this exact format so it is easy to copy:

```
<title>

<body>
```

Rules for the title:
- 72 characters or fewer
- Imperative mood ("add", "fix", "remove" — not "added" or "fixes")
- No trailing period
- Match the casing and prefix style of the repo's existing commits

Rules for the body:
- Explain the *why*, not just the *what*
- Wrap lines at 72 characters
- Use bullet points if there are multiple distinct changes
- Omit the body entirely if the title is self-explanatory and the diff is small

Do not include any explanation or commentary outside the code block — just the commit description itself, ready to copy.
