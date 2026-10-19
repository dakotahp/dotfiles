---
description: Downloads a YouTube video's audio and uploads it to the user's Audiobookshelf as a podcast episode, so it can be listened to later. Use whenever the user gives a YouTube URL and wants it as audio/podcast, or runs /video-to-podcast.
allowed-tools: Bash
---

Turn a YouTube URL into an episode of the "YouTube Videos" podcast in Audiobookshelf.

Pipeline: `yt-dlp` (audio) → `abs-upload` (in this repo's `bin/`, on `$PATH`).

**Run every Bash call in this skill with `dangerouslyDisableSandbox: true`.** `op` (1Password) and the local Audiobookshelf server are unreachable from the default sandbox.

---

## Step 1: Download audio + title

```bash
WORKDIR=$(mktemp -d)
yt-dlp -x --audio-format mp3 -o "$WORKDIR/audio.%(ext)s" "<url>"
yt-dlp --print "%(title)s" "<url>"
```

If `yt-dlp` or `ffmpeg` is missing, tell the user and stop.

---

## Step 2: Upload

```bash
abs-upload -t "<video title>" "$WORKDIR/audio.mp3"
```

The podcast defaults to "YouTube Videos" and is created on the first upload. Use `-p "<name>"` only if the user asks for a different podcast. Credentials come from 1Password, so never print or write them.

---

## Step 3: Clean up

```bash
rm -rf "$WORKDIR"
```

---

## Final output

One line: the episode title and the podcast it went to. If the script fails, show its error message.
