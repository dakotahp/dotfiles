# proofread

A Claude Code skill for checking a piece of writing without rewriting it.

This README explains the thinking behind the skill so it stays focused over time. At the same time, it is restrained to now remove the voice and personality.

## How it works: two phases, both flag-only

**Phase 1, Mechanics.** The objective layer. Spelling, typos, grammar, punctuation, US spelling, the Oxford comma, and internal consistency (capitalization, hyphenation, number style, quote style). These have right answers.

**Phase 2, Blind-spot checks.** The structural layer, limited to three things that are easy to miss in your own draft but still concrete enough to point at without it becoming a matter of taste:

1. **Person of address.** Whether the writing drifts between "I," "we," and "you" without meaning to. A deliberate shift (open wide with "we," then narrow to "you") is fine; an accidental wobble mid-paragraph is the thing to catch.
2. **Verb tense.** Whether the tense stays consistent, or slips for no reason.
3. **Paragraph structure.** A simple test: can you name the one job each paragraph does? If a paragraph is doing two jobs it might want splitting; if two paragraphs share a job they might want merging.

Both phases only ever produce a **list you choose from**. The output separates clear fixes from judgment calls, and Phase 2 reports "clean" explicitly so you know a check actually ran rather than being skipped.

## What it deliberately will not do

The guardrails matter as much as the checks. A naive grammar pass "corrects" exactly the choices that make casual writing good, so the skill is told to leave these alone:

- Contractions, sentence fragments, one-line paragraphs, starting a sentence with "And" or "But." These are intentional casual style, not errors.
- Word choice, phrasing, voice, tone, register. It does not reach for a "better" word.
- Formality. It never nudges writing toward sounding more corporate or "professional."

When something could plausibly be an intentional choice rather than a mistake, the rule is to keep it out of the main list and at most note it as a judgment call. High signal over a long list.

## Why a skill, and not just asking

Two reasons. First, consistency: the boundaries above only hold if they are written down. Ask a fresh model to "proofread this" and it will quietly start editing your voice. The skill is the contract that keeps it in its lane. Second, it doubles as a reminder to me of what I actually want from a review, which is why this README exists.

## Files

- `SKILL.md`: the instructions Claude loads and follows.
- `README.md`: this file, the rationale for humans.
