# Deployment Guide

Ephemeral Burst Cache is designed to be disposable.  
The preferred deployment is short-lived and local or serverless. Long-running persistent deployments defeat the purpose.

**Primary metric: cost efficiency only.**

---

## 1. Local Docker (Recommended)

### Prerequisites
- Docker + Docker Compose

### Start

```bash
docker compose up -d
```

This launches a pure Redis instance with:
- No RDB snapshots (`--save ""`)
- No AOF (`--appendonly no`)
- Automated healthcheck (`redis-cli ping`)
- Port `6379` exposed

### Verify

```bash
redis-cli ping
# → PONG

# Full automated healthcheck
ruby bin/healthcheck
```

### Create a burst

```bash
ruby bin/burst start 600
```

Example output:
```
Burst started
  uuid:  3f8a9c2e-...
  ttl:   600s
  ns:    burst:3f8a9c2e-...:*
```

### Stop / Destroy

```bash
docker compose down
# or simply let the container die — nothing is persisted
```

---

## 2. Nix Development Shell

```bash
nix develop
```

This provides:
- `redis`
- `ruby_3_3`
- `docker-compose`

You can then run Redis manually:

```bash
redis-server --save "" --appendonly no
```

Or use the same Docker Compose from inside the shell.

---

## 3. Serverless / Remote Ephemeral (Upstash)

For zero-local-infra testing:

```bash
curl -X POST https://upstash.com/start-redis
```

This returns a temporary Redis endpoint (no account required for short experiments).  
Treat the returned credentials as a 10-minute burst window and discard them afterward.

Set the environment variable and use the same Ruby tooling:

```bash
export REDIS_URL="rediss://..."
ruby bin/burst start
ruby bin/healthcheck
```

---

## 4. Ruby Control Plane

Install dependencies once:

```bash
bundle install
```

Available commands:

| Command                | Description                          |
|------------------------|--------------------------------------|
| `burst start [ttl]`    | Create a new burst (default 600s)    |
| `burst status <uuid>`  | Show remaining TTL and metadata      |
| `burst kill <uuid>`    | Immediately destroy the namespace    |
| `healthcheck`          | Run full automated health checks     |

All keys live under `burst:{uuid}:*` and inherit the TTL.

---

## Automated Health Checks

Two layers are provided:

1. **Docker healthcheck** — runs continuously inside the container (`redis-cli ping`).
2. **Ruby healthcheck** (`bin/healthcheck`) — verifies:
   - Redis connectivity
   - Persistence is disabled
   - AOF is off
   - Namespace isolation works
   - TTL enforcement works

Exit code `0` = healthy, `1` = failed. Suitable for CI or pre-burst validation.

---

## Design Constraints for Deployment

- **Cost efficiency is the primary metric.**
- **Never enable persistence** (no AOF, no RDB).
- Prefer `--rm` / one-shot containers.
- Prefer short TTLs (300–900 seconds).
- Treat every deployment as temporary.
- If you need multi-node or long-lived state, this is the wrong tool.

---

## Production Note

This project intentionally optimizes for *disappearance* and low cost.  
If you find yourself adding volumes, backups, or heavy monitoring dashboards, you are building a different system.
