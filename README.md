# Ephemeral Burst Cache (EBC)

Short-lived, zero-persistence working memory for a human + agents during a high-energy 5–15 minute window.

When the energy drops, everything dies. No residual state. No saved connections. No cleanup tax.

## Core Idea

Most tools assume you want long-lived state.  
This one assumes the opposite.

You open a burst.  
You and a few agents share a temporary namespace.  
You talk fast, in short turns.  
Agents can talk to you and to each other.  
When the window ends (or the energy leaves), every participant — including you — must output one short systemised POV.  
Then the entire burst is destroyed.

This matches high-associative, short-attention, high-energy working styles.

## Two Layers

### 1. Ephemeral Burst Cache (EBC)
The shared room.

- Lifetime: hard TTL 600–900 seconds (default 10 min)
- Persistence: none
- Namespace: `burst:{uuid}:*`
- Storage options: pure Redis (no AOF/RDB), Upstash free ephemeral, or in-process dict

### 2. Burst Group
The discussion that happens inside the room.

- 3–5 agents + human
- Parallel short conversations
- Agents can address each other
- Forced crystallisation at the end: every participant produces a short systemised point of view
- Then the burst dies

## Quick Local Spin-up

```bash
docker run --rm -it --name ebc -p 6379:6379 redis:alpine redis-server --save "" --appendonly no
```

Then in another terminal:

```bash
redis-cli
SET burst:demo:status "live" EX 600
```

## Design Principles

- Short by default
- Disposable by design
- No long-term connections
- Energy-matched, not deep-work matched
- Crystallise or die

## Status

Concept stage.  
Minimal runnable version exists (Redis one-liner).  
Wrapper scripts and multi-agent orchestration still to be built.

---

Born from a conversation about short high-energy windows, loneliness, group chats that never happened, and the desire for infrastructure that dies when the charge leaves.
