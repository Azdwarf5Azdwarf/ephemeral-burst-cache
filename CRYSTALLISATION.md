# Crystallisation & Save Vote Protocol

After a burst ends, nothing is saved by default.

A short, external **Save Vote** decides what (if anything) is promoted out of the ephemeral namespace.

This step lives *outside* the high-energy burst. It is the deliberate safety layer.

---

## Goals

- Disposal is the default
- Promotion requires explicit multi-party agreement
- Human can lose the vote
- Decisions are grounded in external memory context via secure API calls
- Cost efficiency remains the primary metric

---

## Participants

- 1 human
- 3–5 agents

Each participant has equal voting weight by default.

---

## Protocol (Authenticated Majority)

This is the recommended starting protocol. It is simple, cheap, and sufficient for internal use.

### 1. Candidate Extraction
At burst end the control plane collects short candidate outputs from the shared namespace.

### 2. Context Grounding
Each voter (human + agents) may make secure API / MCP calls to external memory or tools to ground their decision.

### 3. Vote Submission
Each voter submits a signed payload:

```json
{
  "burst_id": "uuid",
  "voter_id": "human|agent-1|...",
  "vote": "save|discard",
  "reason": "one short sentence",
  "context_refs": ["optional external references"],
  "timestamp": "ISO-8601",
  "signature": "..."
}
```

Signatures can be JWT, HMAC, or asymmetric keys. All communication happens over HTTPS.

### 4. Tally
A neutral tally endpoint (or local script) verifies signatures, counts votes, and produces:

- Majority result
- Per-voter record (for audit)
- Short justification summary

### 5. Promotion or Death
- Items that receive majority **save** are written to durable storage.
- Everything else is deleted with the burst namespace.

The human can lose. That is intentional.

---

## Security Properties (Current Protocol)

| Property            | Status                          |
|---------------------|---------------------------------|
| Authenticity        | Yes (signed votes)              |
| Integrity           | Yes (HTTPS + signatures)        |
| Non-repudiation     | Yes                             |
| Audit trail         | Yes                             |
| Vote privacy        | No (voters are identifiable)    |
| Threshold trust     | No (simple majority)            |

Stronger protocols (blind signatures, threshold cryptography, MPC tallying) can be added later if needed. They are intentionally deferred to keep cost and complexity low.

---

## Design Notes

- The vote process itself is short-lived and external to the Redis burst.
- Agents vote with the same weight as the human.
- External context calls happen before the vote is cast, not after.
- The entire crystallisation step should itself be cheap and fast.

---

## Future Hardening Options

- Blind signatures for vote anonymity
- Threshold signatures / secret sharing among agents
- Homomorphic or MPC tallying (only the final result revealed)
- Higher threshold (e.g. 4-of-6) for more conservative promotion

These are optional. The authenticated majority protocol is the correct default for cost-efficient operation.
