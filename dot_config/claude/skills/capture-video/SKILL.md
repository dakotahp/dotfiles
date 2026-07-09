---
description: Downloads a YouTube video's audio, transcribes it locally with whisper.cpp (accuracy-optimized), and files a summarized note into the Obsidian vault. Use whenever the user gives a YouTube URL and wants it captured/summarized, or runs /capture-video.
allowed-tools: Bash, Read, Write, AskUserQuestion, Glob
---

Turn a YouTube URL into a terse, scannable vault note: fully local, no external transcription API, no local-LLM notes step (Claude reads the transcript and writes the note directly).

Pipeline: `yt-dlp` (audio) → `whisper.cpp` (transcript, `large-v3` model) → Claude (summary + filing).

**Priority is transcription accuracy, not speed.** Always use the full `large-v3` model, never `turbo` or a quantized variant, even though it's slower.

**Run every Bash call in this skill with `dangerouslyDisableSandbox: true`.** The default sandbox blocks writes outside the vault directory (breaks `mktemp`, `~/.cache`, scratch dirs) and blocks GPU/Metal access (whisper.cpp silently falls back to CPU, or errors on `ggml_metal_buffer_init`). Both are required for this pipeline to work and to run at a usable speed.

---

## One-time setup (check first, install if missing)

Check for the binary and model before running the pipeline:

```bash
which whisper-cli || which main   # whisper.cpp binary; newer builds ship `whisper-cli`, older ship `main`
ls ~/.cache/whisper.cpp/ggml-large-v3.bin 2>/dev/null
```

If `whisper-cli`/`main` is missing:

```bash
brew install whisper-cpp
```

If the model is missing, download it (one time, ~3.1GB):

```bash
mkdir -p ~/.cache/whisper.cpp
curl -L -o ~/.cache/whisper.cpp/ggml-large-v3.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin
```

Do not substitute `ggml-large-v3-turbo.bin` or a `-q5`/`-q8` quantized file for this — they trade accuracy for speed, which is the wrong tradeoff here. Tell the user if a large download is about to start before kicking it off.

---

## Step 1 — Download audio + metadata

Work in a scratch directory so cleanup is trivial:

```bash
WORKDIR=$(mktemp -d)
yt-dlp -x --audio-format mp3 -o "$WORKDIR/audio.%(ext)s" "<url>"
yt-dlp --print "%(title)s|||%(uploader)s|||%(upload_date)s" "<url>"
```

Parse the title/uploader/upload_date line for use in the note's frontmatter later (`upload_date` is `YYYYMMDD` — reformat to `YYYY-MM-DD`).

---

## Step 2 — Convert to whisper.cpp's required format

whisper.cpp needs 16kHz mono WAV:

```bash
ffmpeg -i "$WORKDIR/audio.mp3" -ar 16000 -ac 1 -c:a pcm_s16le "$WORKDIR/audio.wav" -y
```

---

## Step 3 — Split on silence, then transcribe each segment separately

**Do not run whisper.cpp on the full audio file in one shot.** Extended pauses/silence (dramatic pauses, thinking pauses, edit gaps) push whisper.cpp into a repetition-loop hallucination, where it gets stuck emitting the same line over and over instead of transcribing what's actually said. This can silently destroy the majority of a video's content while still exiting cleanly (exit code 0, no error) — the only tell is repeated/near-duplicate lines in the output. Splitting on silence first keeps each chunk too short to loop.

Detect silence boundaries:

```bash
ffmpeg -i "$WORKDIR/audio.wav" -af "silencedetect=noise=-30dB:d=0.6" -f null - 2> "$WORKDIR/silence.log"
grep "silence_" "$WORKDIR/silence.log"
```

Get total duration:

```bash
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$WORKDIR/audio.wav"
```

From the `silence_start`/`silence_end` pairs and total duration, compute speech segments: `[0, first silence_start]`, then `[silence_end_n, silence_start_n+1]` for each gap, then `[last silence_end, total_duration]`. Skip segments shorter than ~1s (noise). Cut each segment:

```bash
ffmpeg -y -i "$WORKDIR/audio.wav" -ss "<start>" -t "<duration>" -ar 16000 -ac 1 -c:a pcm_s16le "$WORKDIR/segments/seg_<NNN>.wav" -loglevel error
```

Transcribe each segment independently:

```bash
whisper-cli -m ~/.cache/whisper.cpp/ggml-large-v3.bin -f "$WORKDIR/segments/seg_<NNN>.wav" -otxt -of "$WORKDIR/segments/seg_<NNN>" -np
```

(Use `main` in place of `whisper-cli` if that's what Step 0 found.) Before concatenating, sanity-check each segment's `.txt` for repeated/near-duplicate lines (e.g. `sort file | uniq -c | sort -rn | head -1` — a high count means it still looped, and that segment may need splitting further). Then concatenate all segment `.txt` files in order into `$WORKDIR/full_transcript.txt` and read that.

---

## Step 4 — Summarize

Read the transcript and write a **terse, scannable bullet-list summary** — not a rehash of the transcript prose. Match the density and format established in `2_Areas/Communication/Moving Past Small Talk.md`: lead with the core framework/thesis as a bolded one-liner, then bullets for the key structural pieces, then a short "how it works" sequence if the content is procedural. Strip filler, repetition, and rambling — keep only what the user would actually reference later. Keep the original YouTube URL as the first line so the full source is one click away if the summary isn't enough.

---

## Step 5 — File it

Same folder-matching approach as `/process-clippings`:

```bash
obsidian folders vault=ObsidianPersonal folder="2_Areas"
```

Match the video's topic against existing subfolder names. If there's a clear match, file there without asking. If not, ask the user (top 2 candidates + offer to create new).

Write with:

```bash
obsidian create vault=ObsidianPersonal path="2_Areas/<Subfolder>/<Descriptive Title>.md" content="<content>"
```

File name: descriptive, no date prefix (e.g. `Moving Past Small Talk.md`, not `2026-07-08 Video.md`).

---

## Step 6 — Clean up

```bash
rm -rf "$WORKDIR"
```

Delete the scratch audio/wav/transcript files. Do not delete anything from the vault itself in this step — that's `/process-clippings`' job, not this skill's.

---

## Final output

Tell the user the file path created and which folder it landed in. If Step 0 triggered a fresh install or a large model download, mention that too — it only happens once.
