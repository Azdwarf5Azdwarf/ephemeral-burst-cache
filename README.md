# Ephemeral Burst Cache (EBC)

**Short-lived shared memory for you and four haiku agents.**

A disposable conversation space that lives for ~10 minutes and then deletes
itself. You talk, four haiku agents answer in seventeen syllables each, and
when the burst ends the thread is distilled into three memes — plus, if
anything in it actually mattered, one short saved note. Everything else dies
with the TTL.

Exactly two AI dependencies, with a clean split:

- **Grok (xAI) generates** — chat completions power the haiku agents and the
  meme prompt writer, and Grok's image model renders the memes.
- **Claude Opus reasons** — the last model in the pipeline. It cleans up the
  conversation and saves the important stuff to `saved/` *if needed*; most
  bursts should die, and Opus is told to be picky.

## The Lineup

Four fixed haiku agents, one voice each:

| Agent   | Voice                                                  |
|---------|--------------------------------------------------------|
| Frost   | Stark, wintry — sees the cold truth and says it plainly |
| Blossom | Gentle, optimistic — finds the small beautiful detail   |
| Cicada  | Restless, loud — obsessed with time running out         |
| Ember   | Warm, wry — quietly funny, always the last word         |

They read the whole thread, including each other, and reply in strict haiku.

## Architecture

```
┌─────────────────────────────────────┐
│           Burst Group               │
│     you + 4 haiku agents            │
│  every agent reply is a 5-7-5 haiku │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│      Ephemeral Burst Cache          │
│  pure Redis · no AOF · no RDB       │
│  namespace: burst:{uuid}:*          │
│  hard TTL 600–900s                  │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│        Crystallisation              │
│  Grok reads the thread and writes   │
│  3 meme prompts · Grok's image      │
│  model renders them into memes/     │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│    Curation (the last reasoning     │
│    model) · Claude Opus cleans up   │
│    the thread and saves what        │
│    matters to saved/ — if anything  │
│    does · then the TTL wins         │
└─────────────────────────────────────┘
```

See **[CRYSTALLISATION.md](CRYSTALLISATION.md)** for how the ending works.

## Quick Start

```bash
# 1. Pure Redis, no persistence
docker compose up -d

# 2. The two required secrets
cp .env.example .env    # fill in XAI_API_KEY and ANTHROPIC_API_KEY
export XAI_API_KEY=...
export ANTHROPIC_API_KEY=...

# 3. Dependencies
bundle install
```

Then run a burst:

```bash
ruby bin/burst start            # → prints a uuid
ruby bin/burst say <uuid> "should I commit to this idea or keep scaffolding"
ruby bin/burst crystallise <uuid>   # → 3 memes in memes/, then Opus curates
```

## CLI

| Command                    | Description                                    |
|----------------------------|------------------------------------------------|
| `burst start [ttl]`        | Create a burst (default 600s)                  |
| `burst say <uuid> <text>`  | Post a message; all four agents reply in haiku |
| `burst thread <uuid>`      | Print the thread so far                        |
| `burst status <uuid>`      | Remaining TTL and message count                |
| `burst crystallise <uuid>` | 3 memes via Grok, then Opus curates the thread |
| `burst curate <uuid>`      | Opus only: clean up the thread, save what matters |
| `burst kill <uuid>`        | Destroy the namespace immediately              |
| `healthcheck`              | Run the automated health checks                |

## Health Checks

```bash
ruby bin/healthcheck
```

Verifies Redis is alive, persistence is off, TTLs are enforced, and both API
keys are configured.

## Nix

```bash
nix develop
```

For people who like their chaos reproducible.

## Project Layout

```
bin/burst                  CLI entrypoint
bin/healthcheck            automated checks
lib/ebc/config.rb          env-driven configuration
lib/ebc/grok_client.rb     Grok: generation (chat + images)
lib/ebc/haiku_agent.rb     the four-agent lineup
lib/ebc/burst.rb           Redis-backed burst lifecycle
lib/ebc/crystallisation.rb thread → 3 meme prompts → 3 images
lib/ebc/curator.rb         Claude Opus: the last reasoning model
```

## Core Principles

- **Cost efficiency first** — cheap generation, short bursts, tiny outputs
- **Short by default** — 10 minutes is already generous
- **Disposable by design** — the system *wants* to die
- **Haiku only** — agents get seventeen syllables, which is plenty
- **Crystallise or die** — the final output is three memes, not a whitepaper
- **Reason last** — Opus gets the final word on what survives, and its
  default answer is "nothing"

## Status

Personal experiment. Play level. Not for production, not for your manager.

---

Built for people who think in bursts and then immediately forget they did.
