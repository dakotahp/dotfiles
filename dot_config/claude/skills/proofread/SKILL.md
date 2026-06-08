---
name: proofread
description: Use when the user wants to proofread or get a blind-spot check on a piece of writing. Triggers include "proofread", "/proofread", "check this draft", "check my writing".
allowed-tools: Read, Bash
---

Two-pass review of casual-but-professional writing (blog posts, LinkedIn posts). **Phase 1** catches mechanical errors. **Phase 2** flags structural blind spots. Both passes only *flag* issues as a list the user chooses to apply. **Never rewrite for voice, tone, formality, or word choice.**

This skill's value is its restraint. A naive pass "corrects" exactly the choices that make casual writing good. Report genuine issues, point at them precisely, and leave the voice alone.

## First, get the draft

Resolve the input in this order:

- If the user gave a **file path or `[[wikilink]]`**, read it. For vault notes use the obsidian CLI: `obsidian vault=ObsidianPersonal read path="<vault-relative path>"`. For an arbitrary filesystem path, use the Read tool. Note line numbers so flags are easy to locate.
- Otherwise, review the **text the user pasted**, or, if you have been drafting together, the latest version of the draft in the conversation.

If it is genuinely ambiguous what to review, ask before proceeding. Otherwise just proceed.

## Phase 1, Mechanics

### Flag these (and only these)

Read the whole draft first, then collect issues in reading order:

1. **Spelling & typos**: misspellings, doubled words ("the the"), transposed letters, missing or repeated words.
2. **Grammar errors**: subject-verb agreement, wrong verb form, dangling or misplaced modifiers, wrong word (their/there/they're, its/it's, fewer/less, affect/effect). Cross-passage tense drift is handled in Phase 2, not here.
3. **Punctuation**: apostrophe misuse, comma splices that genuinely impede reading, missing or misplaced punctuation that changes meaning, mismatched quotes or parentheses.
4. **US spelling**: flag British variants (colour to color, organise to organize, -re to -er).
5. **Oxford comma**: flag a missing serial comma in lists of three or more items.
6. **Internal consistency**: within this one piece only, inconsistent capitalization of a term, hyphenation (email vs e-mail), number style (5 vs five), straight vs curly quotes and apostrophes.

### Never flag these (hard guardrails)

These are intentional casual choices, not errors. Do not flag them, do not mention them, do not "offer" them as improvements:

- Contractions, sentence fragments, one-sentence paragraphs
- Sentences starting with And / But / So / Because
- Conversational asides, rhetorical questions, deliberate informality, slang
- Word choice, phrasing, tone, voice, register
- Structure and flow **beyond the three specific Phase 2 checks below**. No comments on openings, pacing, repetition, or word-level style.
- **Em dashes**: the user's voice. The no-em-dash rule in CLAUDE.md governs Claude's output, not the user's writing.
- Length, formality, or anything in the name of sounding "more professional"

**Tie-breaker:** if something could plausibly be an intentional casual choice rather than an error, keep it out of the Fixes list. At most it belongs in Judgment Calls.

This is proofreading, not editing. Do not suggest rewrites for clarity or style.

## Phase 2, Structural blind-spot checks

Three checks, no more. As in Phase 1, you *flag* and the user decides. Never rewrite or reorganize. Tone (whether a passage sounds pompous or preachy) is deliberately **out of scope for now**; do not comment on it.

1. **Person of address (POV consistency).** Identify the dominant address: first person ("I" / "we"), second ("you"), or third ("a manager"). Flag each place it shifts. A deliberate shift at a section seam (for example, opening wide with "we," then narrowing to "you") is fine; flag the *unmarked drift mid-passage* and let the user judge each one. Point at the exact words. Do not rewrite.
2. **Verb tense.** Identify the base tense (usually present for advice and essays). Flag genuine inconsistencies, or a tense wrong for the circumstance (for example, a past anecdote slipping into present). Do NOT flag correct variation: present for general truths plus future for consequences is fine. Only flag unmotivated shifts.
3. **Paragraph structure (one-job test).** Name the single job each paragraph does. Flag a paragraph doing two distinct jobs (candidate to split), adjacent paragraphs sharing one job (candidate to merge), or a break that lands mid-thought. Show the named jobs so the user sees the logic. Do not reorganize.

## Output

Return two labeled sections. Apply nothing automatically; the user decides what to take.

### Phase 1, Fixes

Clear mechanical errors, in reading order:

> - **[line N / ¶2]** "original snippet" → "corrected snippet" (*short reason*)

**Judgment calls (ignore freely):** borderline items that might be intentional. Keep it short; omit if there are none.

> - "snippet" (*what's ambiguous, and the optional fix*)

### Phase 2, Blind-spot checks

Report all three blocks every time, including when clean, so the user knows each was actually checked:

- **Person of address:** state the dominant address, then bullet each shift as **[loc]** "snippet": shifts from X to Y, intentional? Say "consistent, no drift" if clean.
- **Tense:** state the base tense, then either "consistent, no issues" or bullet each unmotivated shift.
- **Paragraph jobs:** one bullet per paragraph naming its job, then a one-line verdict (principled, or which to split/merge).

End with a one-line tally, for example: `Phase 1: 6 fixes + 3 judgment calls. Phase 2: 1 POV drift, tense clean, 1 paragraph to split.`

If the whole draft is clean, say so in one line per phase. Never invent issues to look useful.
