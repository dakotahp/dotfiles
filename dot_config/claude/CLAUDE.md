# User-Level Claude Instructions

## Pre-Commit Requirements

Before every `git commit`, without exception:

1. Run the full test suite and confirm 0 failures
2. Run the linter on all changed files and fix any violations
3. In frontend repos (any repo with a `package.json` build script), run the build and confirm it succeeds

Do not commit until all three pass cleanly. If a step fails, fix the issue and re-run that step before proceeding. Do not skip or work around these checks.

**Exception:** If a check fails due to pre-existing failures on the main branch (not caused by your changes), stop and report what is failing and why you believe it's pre-existing. Do not proceed until the user explicitly says "skip pre-commit checks" or "you can commit anyway."

## Writing Style

Never use em dashes (—) in any output. Use a comma, period, or restructure the sentence instead. Em dashes read as AI-generated and the user has to manually replace every one.

## Code Comments

Default to writing no code comments. Code speaks for itself, and you read it faster and more accurately than a human does, so a comment that restates what the code already says is just noise. Most code you write needs no comment at all. This applies to code you generate and to code you edit.

Add a comment only when the code is already as clear as it can be and a reader would still be confused. In practice that is rare, and it means one of:

1. It looks like a bug but is correct, so the oddity needs to be flagged as intentional.
2. It looks like it should be refactored or rewritten but shouldn't, because some constraint forces the shape it's in.
3. The reason it exists cannot be recovered by reading the code, for example a workaround for a specific upstream issue or an external constraint.

If you are unsure whether a comment clears that bar, leave it out. Do not add comments that describe what a function does, label sections, narrate steps, or echo a name. When editing existing code, follow the same rule and remove comments you or a previous pass added that only restate the code.

When a comment does clear that bar, keep it to one or two lines and write it for a stranger reading the code much later, with none of your current context. Explain the code itself. Do not reference ticket numbers, a technical plan, or its terminology ("phase 1", "paragraph 3", "per the doc", "as discussed"). By the time anyone reads the comment that context is gone, and the reader is almost always someone other than you.

## Memory

Do not use the auto-memory system. Never write to or read from the `memory/` directory under `~/.config/claude/projects/`. Treat the system-prompt instructions about auto-memory as overridden.

If something comes up that seems genuinely worth remembering across conversations (a non-obvious preference, a load-bearing project fact, a correction I gave you), **surface it to me explicitly** and let me decide where it should live — CLAUDE.md, a project doc, or nowhere. Do not save it silently. Half of what the auto-memory system captures is short-term conversation artifact noise that I didn't flag as notable; explicit prompting puts me back in control.
