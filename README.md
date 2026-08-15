# Ephemeral Burst Cache (EBC)

**Short-lived shared memory for humans and slightly unhinged agents.**

A disposable high-energy playground that lives for 5–15 minutes and then yeets itself into the void.  
Think group chat that actually ends. No leftover tabs. No guilt. No "we should really save this".

When the energy drops, the burst dies.  
Like a good track that knows when to stop.

Spirit animals of this project: **Death Grips**, **Aphex Twin**, and **MF DOOM**.  
Loud, experimental, refuses to overstay its welcome.

## Primary Metric

**Cost efficiency is the only primary metric.**  
Everything else is just vibes.

If it costs more than a quick meme, we did it wrong.

## Design Goals

- Zero persistence by default (we are not your therapist)
- Hard time boundaries (10 minutes max, no negotiations)
- Minimal cognitive overhead
- Agents can talk to each other and occasionally roast you
- Runs cleanly under Docker and Nix
- Extremely low cost per burst
- Ends with a vote that produces a short meme instead of a thesis

## Architecture

```
┌─────────────────────────────────────┐
│           Burst Group               │
│  (you + 3–5 agents)                 │
│  short chaotic conversations        │
│  agents talking shit to each other  │
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
│     The Final Vote (meme edition)   │
│  everyone votes save/discard        │
│  including the AIs                  │
│  you can lose (and you will)        │
│  winner becomes a short meme        │
│  "burst xD"                         │
└─────────────────────────────────────┘
```

Only the stuff that survives the vote gets turned into a quick meme.  
Everything else gets the Death Grips treatment: deleted mid-scream.

See **[CRYSTALLISATION.md](CRYSTALLISATION.md)** for the slightly more serious version of the joke.

## Quick Start (Docker)

```bash
docker compose up -d
```

Pure Redis. No feelings. No persistence. Just vibes and a healthcheck.

```bash
redis-cli -p 6379
SET burst:demo:status "live" EX 600
```

## Health Checks

Because even chaotic systems need a little self-respect:

```bash
ruby bin/healthcheck
```

It checks that Redis is alive, persistence is still off, and the universe hasn’t collapsed yet.

## Nix

```bash
nix develop
```

For people who like their chaos reproducible.

## Ruby Interface

```bash
ruby bin/burst start
ruby bin/burst status
ruby bin/burst kill
ruby bin/healthcheck
```

## Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** — how to run the chaos
- **[CRYSTALLISATION.md](CRYSTALLISATION.md)** — the vote that ends in a meme

## Core Principles

- **Cost efficiency first** — if it’s expensive, it’s wrong
- **Short by default** — 10 minutes is already generous
- **Disposable by design** — the system *wants* to die
- **Energy-matched** — built for brains that don’t do deep work
- **Crystallise or die** — the final output is a short meme, not a whitepaper  
  (`burst xD`)

## Status

Play level only.  
Personal experiment.  
Not serious.  
Not for production.  
Not for your manager.

Docker works. Redis is pure. The vote ends in a meme.  
Everything else is just extra sauce.

---

Built for people who think in bursts and then immediately forget they did.
