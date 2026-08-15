# Ephemeral Burst Cache (EBC)

**You don't record a group chat. You take a photo after it has ended.**

A burst is ten minutes of talking nonsense in rhyme with three poets and
whoever you invited. Nothing you say is kept. When it's over, a judge says
one last thing out loud, and then you get a picture.

If you took a real photo of you and your friends, the poets get drawn into
it — they were there too. Your friends hold still, because they were actually
there; only the drawn ones move. That's the whole animation, and it's honest
about who was real.

The picture is the only thing that survives. Its filename says how the night
went, so a folder of these is browsable by feeling:

```
photos/2026-08-15-delighted.gif
photos/2026-08-11-restless.gif
```

## Who does what

| | |
|---|---|
| **Claude Haiku 4.5 ×3** | The poets. Haiku models that write sonnets, because the only rule is that we rhyme. |
| **Claude Opus 4.8** | The judge. Arrives at the end, is the only one who doesn't have to rhyme, and says whatever it wants. |
| **Grok** | The camera. Doesn't talk. Only takes the picture. |

## The poets

| Poet | Voice |
|---|---|
| **Frost** | Stark and wintry — sees the cold truth and says it plainly |
| **Cicada** | Restless and loud — can hear the clock running out on all of this |
| **Ember** | Warm and wry — quietly funny, and always takes the last word |

Each replies with one ABAB quatrain, and **the rhyme carries between them**:
every poet after the first opens on the sound the previous one closed on. The
conversation rhymes as a group, not one voice at a time.

## The shape

```
        you  +  a friend you invited  +  3 poets
                          │
                          ▼
              rhyming quatrains, handed between voices
                          │
                          ▼
        Redis · no AOF · no RDB · hard TTL
                          │
                          ▼
        the judge says its piece, and is never written down
                          │
                          ▼
        the poets are drawn into your photo → one animated picture
                          │
                          ▼
              the poems die.  the picture stays.
```

See **[THE_PHOTO.md](THE_PHOTO.md)** for how the ending works.

## Quick start

```bash
docker compose up -d          # pure Redis, no persistence
cp .env.example .env          # three keys go in here
bundle install
```

Then take a walk:

```bash
ruby bin/burst start                        # → a uuid
ruby bin/burst join <uuid> Sam              # your friend joins
ruby bin/burst say <uuid> "the sky looks personally offended"
ruby bin/burst photo <uuid> us.jpg          # → photos/…-delighted.gif
```

## Commands

| Command | |
|---|---|
| `burst start [ttl]` | Start a burst (default 600s) |
| `burst invite <uuid>` | Print the code a friend needs |
| `burst join <uuid> <name>` | Join someone else's burst |
| `burst say <uuid> <text>` | Take your turn; the poets answer |
| `burst thread <uuid>` | The conversation so far |
| `burst status <uuid>` | Who's here and how long is left |
| `burst photo <uuid> [pic]` | The judge speaks, then the picture is taken |
| `burst kill <uuid>` | Destroy it now |
| `healthcheck` | Redis, keys, and the GIF tool |

## Requirements

Redis, Ruby 3.3, and **ImageMagick** (the picture). `nix develop` provides
all of it.

Two API keys: `ANTHROPIC_API_KEY` and `XAI_API_KEY`.

## Core principles

- **Nothing is recorded** — no transcript, no summary, no saved note
- **Short by default** — ten minutes is already generous
- **We only rhyme** — and the rhyme is the group's, not each voice's
- **The judge says its piece once** — never written, never re-read
- **The picture is the memory** — and you can tell from it whether it was fun

## Status

Personal experiment. Play level. Not for production, not for your manager.

---

Built for people who think in bursts and then immediately forget they did.
