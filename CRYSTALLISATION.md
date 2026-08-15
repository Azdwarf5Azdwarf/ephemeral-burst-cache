# Crystallisation

(also known as "the part where we decide what the burst was actually about")

After a burst ends, nothing is saved by default. Instead of a summary, a
document, or a thoughtful reflection, the thread is compressed into
**five memes** — and those five images are the only thing that survives.

---

## How it works

1. The burst ends (TTL fires, or you run `burst crystallise <uuid>` before it does).
2. The thread — your messages plus the four haiku agents' replies — is pulled from Redis.
3. Grok reads the thread and writes **5 meme image prompts**, each capturing a
   moment, running joke, or mood from the conversation.
4. Grok's image model renders each prompt.
5. The images land in `memes/` as `{uuid}-meme-{n}.png`.
6. The Redis namespace dies with its TTL. No transcript survives.

The whole pipeline is the Grok API and nothing else: one chat call to write
the prompts, five image calls to render them.

---

## Participants

- You
- **Frost**, **Blossom**, **Cicada**, and **Ember** — the fixed haiku lineup

No votes, no democracy, no losing. The thread itself decides what the memes
are about, because the prompts are written from what was actually said.

---

## Output contract

- Exactly 5 images per burst
- Each prompt is visual and specific; any in-image text is caption-length
- If a meme needs a paragraph to explain, the burst failed

---

## Spirit

Most things should die. The few things that live should make you smirk.
Seventeen syllables in, five images out, nothing in between is kept.
