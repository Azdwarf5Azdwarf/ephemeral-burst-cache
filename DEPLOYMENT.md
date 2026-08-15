# Deployment Guide

Ephemeral Burst Cache is designed to be disposable. The preferred deployment
is short-lived and local — you run it on the machine you're walking around
with. Long-running persistent deployments defeat the purpose.

**Primary metric: cost efficiency.** One Redis container, short bursts, and
one picture at the end.

---

## 1. Prerequisites

- Docker + Docker Compose (for Redis)
- Ruby 3.3 (`bundle install` pulls the two gems)
- **ImageMagick** — draws the poets into your photo and assembles the GIF.
  Without it, `burst photo` fails with a clear error.
- *Optional:* an audio player (`ffplay`, `afplay`, `mpv`, `aplay`, `paplay`)
  so the judge can be heard. Without one it prints once instead — either way
  the verdict is never written to disk.

`nix develop` provides all of the above.

Three API keys:

```bash
cp .env.example .env
export ANTHROPIC_API_KEY=...   # 3 poets + the judge
export XAI_API_KEY=...         # the camera
export ELEVENLABS_API_KEY=...  # ears and voice
bundle install
```

---

## 2. Local Docker (recommended)

```bash
docker compose up -d
```

Pure Redis with no RDB snapshots (`--save ""`), no AOF (`--appendonly no`),
a container healthcheck, and port `6379` exposed.

Verify:

```bash
ruby bin/healthcheck
```

Stop:

```bash
docker compose down
# or just let it die — nothing is persisted
```

---

## 3. Nix development shell

```bash
nix develop
```

Provides `redis`, `ruby_3_3`, `docker-compose`, `imagemagick`, and `ffmpeg`.
Run Redis manually if you prefer:

```bash
redis-server --save "" --appendonly no
```

---

## 4. Remote Redis (optional)

Any throwaway managed Redis works — point `REDIS_URL` at it and keep
persistence off:

```bash
export REDIS_URL="rediss://..."
ruby bin/healthcheck   # confirms persistence and AOF are disabled
```

---

## 5. Running a burst

```bash
ruby bin/burst start 600
ruby bin/burst join <uuid> Sam
ruby bin/burst say <uuid> "your line"
ruby bin/burst listen <uuid> walk.m4a
ruby bin/burst photo <uuid> us.jpg
ruby bin/burst kill <uuid>
```

All keys live under `burst:{uuid}:*` — thread, participants, and laughter all
share the burst's TTL and vanish together. **The only artifact that outlives a
burst is the GIF in `photos/`** (`EBC_PHOTO_DIR`).

---

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `ANTHROPIC_API_KEY` | *(required)* | Poets and judge |
| `XAI_API_KEY` | *(required)* | The camera |
| `ELEVENLABS_API_KEY` | *(required)* | STT with laughter tags, and TTS |
| `REDIS_URL` | `redis://127.0.0.1:6379/0` | Burst storage |
| `HAIKU_MODEL` | `claude-haiku-4-5` | The three poets |
| `OPUS_MODEL` | `claude-opus-4-8` | The judge |
| `GROK_IMAGE_MODEL` | `grok-2-image` | Image generation |
| `ELEVENLABS_VOICE_ID` | `21m00Tcm4TlvDq8ikWAM` | The judge's voice |
| `ELEVENLABS_STT_MODEL` | `scribe_v1` | Tags `(laughs)` inline |
| `ELEVENLABS_TTS_MODEL` | `eleven_multilingual_v2` | Speaking the verdict |
| `EBC_FRAME_COUNT` | `4` | Frames in the animated photo |
| `EBC_PHOTO_DIR` | `photos` | Where the pictures land |

Model names follow each vendor's catalogue — override via env if a default is
retired. Note `claude-3-opus` is **retired** and cannot be used; `claude-opus-4-8`
is its documented replacement.

---

## Health checks

Two layers:

1. **Docker healthcheck** — runs continuously in the container (`redis-cli ping`).
2. **Ruby healthcheck** (`bin/healthcheck`) — Redis connectivity, persistence
   off, AOF off, namespace isolation, TTL enforcement, all three API keys, and
   the presence of ImageMagick. It also reports whether an audio player exists,
   which is informational rather than required.

Exit `0` healthy, `1` failed.

---

## Design constraints

- **Never enable persistence** (no AOF, no RDB).
- Prefer short TTLs (300–900 seconds).
- Treat every deployment as temporary.
- Nothing but the photo is allowed to outlive a burst — no transcripts, no
  summaries, no saved verdicts. If you find yourself adding a place to store
  what was said, you are building a different system.
