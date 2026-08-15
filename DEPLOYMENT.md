# Deployment Guide

Ephemeral Burst Cache is designed to be disposable. The preferred deployment
is short-lived and local. Long-running persistent deployments defeat the
purpose.

**Primary metric: cost efficiency.** One Redis container, one API vendor,
three images per burst.

---

## 1. Prerequisites

- Docker + Docker Compose (for Redis)
- Ruby 3.3 (`bundle install` pulls the gem dependencies)
- An xAI API key — Grok generates the haikus and the memes
- An Anthropic API key — Claude Opus is the last reasoning model
  (cleans up the thread, saves the important stuff if needed)

```bash
cp .env.example .env
export XAI_API_KEY=...
export ANTHROPIC_API_KEY=...
bundle install
```

---

## 2. Local Docker (Recommended)

```bash
docker compose up -d
```

This launches a pure Redis instance with:

- No RDB snapshots (`--save ""`)
- No AOF (`--appendonly no`)
- Container-level healthcheck (`redis-cli ping`)
- Port `6379` exposed

Verify:

```bash
ruby bin/healthcheck
```

Stop / destroy:

```bash
docker compose down
# or simply let the container die — nothing is persisted
```

---

## 3. Nix Development Shell

```bash
nix develop
```

Provides `redis`, `ruby_3_3`, and `docker-compose`. Run Redis manually if you
prefer:

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

Treat the endpoint as disposable, like everything else here.

---

## 5. Running a Burst

```bash
ruby bin/burst start 600
ruby bin/burst say <uuid> "your message"
ruby bin/burst thread <uuid>
ruby bin/burst crystallise <uuid>
ruby bin/burst curate <uuid>
ruby bin/burst kill <uuid>
```

All keys live under `burst:{uuid}:*` and share the burst's TTL. Two kinds of
artifact can outlive a burst: crystallised memes in `memes/` (`EBC_MEME_DIR`),
and — when Opus decides the thread earned it — a distilled note in `saved/`
(`EBC_SAVE_DIR`).

---

## Configuration

| Variable            | Default                     | Purpose                        |
|---------------------|-----------------------------|--------------------------------|
| `XAI_API_KEY`       | *(required)*                | Grok API auth (generation)     |
| `ANTHROPIC_API_KEY` | *(required)*                | Claude Opus auth (reasoning)   |
| `REDIS_URL`         | `redis://127.0.0.1:6379/0`  | Burst storage                  |
| `XAI_BASE_URL`      | `https://api.x.ai/v1`       | Grok API endpoint              |
| `GROK_CHAT_MODEL`   | `grok-4-fast-non-reasoning` | Haiku agents + prompt writer   |
| `GROK_IMAGE_MODEL`  | `grok-2-image`              | Meme rendering                 |
| `OPUS_MODEL`        | `claude-opus-5`             | The last reasoning model       |
| `EBC_MEME_DIR`      | `memes`                     | Where crystallised memes land  |
| `EBC_SAVE_DIR`      | `saved`                     | Where Opus's saved notes land  |

Grok model names follow xAI's catalogue — check their docs if a default has
been retired and override via env. `claude-opus-5` is a stable alias on the
Anthropic API.

---

## Health Checks

Two layers:

1. **Docker healthcheck** — runs continuously inside the container (`redis-cli ping`).
2. **Ruby healthcheck** (`bin/healthcheck`) — verifies connectivity,
   persistence off, AOF off, namespace isolation, TTL enforcement, and that
   both API keys are configured.

Exit code `0` = healthy, `1` = failed. Suitable for CI or pre-burst validation.

---

## Design Constraints

- **Never enable persistence** (no AOF, no RDB).
- Prefer short TTLs (300–900 seconds).
- Treat every deployment as temporary.
- If you need multi-node or long-lived state, this is the wrong tool.
- If you find yourself adding volumes, backups, or dashboards, you are
  building a different system.
