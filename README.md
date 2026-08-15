# Ephemeral Burst Cache (EBC)

**Short-lived shared memory for you and four haiku agents.**

A disposable conversation space that lives for ~10 minutes and then deletes
itself. You talk, four haiku agents answer in seventeen syllables each, and
when the burst ends the whole thread is distilled into five memes. The memes
are the only thing that survives. Everything else dies with the TTL.

The **Grok API (xAI) is the only AI dependency** — chat completions power the
haiku agents and the meme prompt writer, and Grok's image model renders the
memes. One vendor, two endpoints, no orchestration framework.

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
│  5 meme prompts · Grok's image      │
│  model renders them · memes/ is     │
│  the only thing that survives       │
└─────────────────────────────────────┘
```

See **[CRYSTALLISATION.md](CRYSTALLISATION.md)** for how the ending works.

## Quick Start

```bash
# 1. Pure Redis, no persistence
docker compose up -d

# 2. The one required secret
cp .env.example .env    # fill in XAI_API_KEY
export XAI_API_KEY=...

# 3. Dependencies
bundle install
```

Then run a burst:

```bash
ruby bin/burst start            # → prints a uuid
ruby bin/burst say <uuid> "should I commit to this idea or keep scaffolding"
ruby bin/burst crystallise <uuid>   # → 5 memes in memes/
```

## CLI

| Command                    | Description                                    |
|----------------------------|------------------------------------------------|
| `burst start [ttl]`        | Create a burst (default 600s)                  |
| `burst say <uuid> <text>`  | Post a message; all four agents reply in haiku |
| `burst thread <uuid>`      | Print the thread so far                        |
| `burst status <uuid>`      | Remaining TTL and message count                |
| `burst crystallise <uuid>` | Generate 5 memes from the thread via Grok      |
| `burst kill <uuid>`        | Destroy the namespace immediately              |
| `healthcheck`              | Run the automated health checks                |

## Health Checks

```bash
ruby bin/healthcheck
```

Verifies Redis is alive, persistence is off, TTLs are enforced, and the Grok
API key is configured.

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
lib/ebc/grok_client.rb     the only AI dependency (chat + images)
lib/ebc/haiku_agent.rb     the four-agent lineup
lib/ebc/burst.rb           Redis-backed burst lifecycle
lib/ebc/crystallisation.rb thread → 5 meme prompts → 5 images
```

## Core Principles

- **Cost efficiency first** — one cheap vendor, short bursts, tiny outputs
- **Short by default** — 10 minutes is already generous
- **Disposable by design** — the system *wants* to die
- **Haiku only** — agents get seventeen syllables, which is plenty
- **Crystallise or die** — the final output is five memes, not a whitepaper

## Status

Personal experiment. Play level. Not for production, not for your manager.

---

Built for people who think in bursts and then immediately forget they did.
