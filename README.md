# Ephemeral Burst Cache (EBC)

**Short-lived shared memory for humans and agents.**

A disposable, high-energy working memory that lives for 5–15 minutes and then completely disappears. Designed for parallel short-burst conversations between a human and multiple agents.

When the energy drops, the burst dies. No residual state. No long-lived connections.

## Primary Metric

**Cost efficiency is the only primary metric.**

Everything else (latency, features, convenience) is secondary.  
The system is considered successful when it delivers useful short-lived coordination at the lowest possible resource cost and then disappears cleanly.

## Design Goals

- Zero persistence by default
- Hard time boundaries
- Minimal cognitive overhead
- Native multi-agent support
- Runs cleanly under Docker and Nix
- Extremely low cost per burst

## Architecture

```
┌─────────────────────────────────────┐
│           Burst Group               │
│  (human + 3–5 agents)               │
│                                     │
│  short parallel conversations       │
│  agents talk to each other          │
│  forced crystallisation at end      │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│      Ephemeral Burst Cache          │
│  pure Redis · no AOF · no RDB       │
│  namespace: burst:{uuid}:*          │
│  hard TTL 600–900s                  │
└─────────────────────────────────────┘
```

## Quick Start (Docker)

```bash
docker compose up -d
```

This starts a pure Redis instance with persistence completely disabled and an automated healthcheck.

Connect:

```bash
redis-cli -p 6379
SET burst:demo:status "live" EX 600
```

## Health Checks

Automated checks are included:

**Docker healthcheck** (runs automatically):
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
```

**Ruby healthcheck** (manual or CI):
```bash
ruby bin/healthcheck
```

It verifies:
- Redis connectivity
- Persistence is disabled (`save` empty)
- AOF is off
- Namespace isolation works
- TTL enforcement works

Exit code `0` = healthy, `1` = failed.

## Nix

```bash
nix develop
```

Drops you into a shell with Redis and Ruby available. Pure and reproducible.

## Ruby Interface

```bash
ruby bin/burst start
ruby bin/burst status
ruby bin/burst kill
ruby bin/healthcheck
```

## Deployment

See **[DEPLOYMENT.md](DEPLOYMENT.md)** for full instructions covering:

- Local Docker
- Nix development shell
- Serverless / Upstash ephemeral Redis
- Ruby control plane usage
- Explicit design constraints

## Core Principles

- **Cost efficiency first** — every design decision is measured against resource cost
- **Short by default** — 10 minutes is the standard window
- **Disposable by design** — the system is happier when it dies cleanly
- **Energy-matched** — built for high-associative, short-attention work styles
- **Crystallise or die** — every participant must emit a short systemised POV before the burst ends

## Status

Early but runnable.  
Docker + pure Redis + healthchecks work today.  
Nix flake and Ruby control plane are being hardened.

---

Built for people who think in bursts.
