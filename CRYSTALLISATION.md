# Crystallisation

(also known as "the part where we decide what the burst was actually about")

After a burst ends, nothing is saved by default. Instead of a summary, a
document, or a thoughtful reflection, the thread is compressed into
**five memes**. Then one last reasoning model — **Claude Opus** — reads the
thread, cleans it up, and decides whether anything actually deserves to be
saved. Usually the answer is no.

---

## How it works

1. The burst ends (TTL fires, or you run `burst crystallise <uuid>` before it does).
2. The thread — your messages plus the four haiku agents' replies — is pulled from Redis.
3. Grok reads the thread and writes **5 meme image prompts**, each capturing a
   moment, running joke, or mood from the conversation.
4. Grok's image model renders each prompt.
5. The images land in `memes/` as `{uuid}-meme-{n}.png`.
6. **The last reasoning model runs:** Claude Opus reads the same thread,
   cleans it up, and judges whether anything is genuinely worth keeping —
   a real idea, a decision, a task, a line too good to lose.
7. If yes, a short distilled note lands in `saved/{uuid}.md`. If not,
   Opus says `NOTHING_WORTH_SAVING` and nothing is written.
8. The Redis namespace dies with its TTL. No transcript survives.

Two models, a clean split: Grok generates (one chat call for the prompts,
five image calls for the memes), Opus reasons (one call, the final word).

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
- At most one saved note per burst, and only when Opus judges it earned —
  a title line plus a few bullets, never a transcript

---

## Spirit

Most things should die. The few things that live should make you smirk —
or actually matter, in which case the last reasoning model writes them down.
Seventeen syllables in, five images and maybe one note out, nothing in
between is kept.
