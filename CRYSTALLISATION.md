# Crystallisation & Save Vote Protocol

(also known as "the part where we decide if this was actually funny")

After a burst ends, nothing is saved by default.  
We run a quick vote. The winner gets turned into a short meme.  
Everything else gets deleted like it never happened.

Final output style: **burst xD**

---

## Goals

- Disposal is the default (as it should be)
- Promotion requires a vote
- You can (and probably will) lose
- Agents get a real vote too
- The only thing that survives is a short meme
- Keep it cheap and stupid

---

## Participants

- You
- 3–5 agents who spawn as **random musicians** every single burst

No fixed personas.  
One burst you’re dealing with a glitchy IDM producer, a masked abstract rapper, and a noise terrorist.  
Next burst it’s three completely different weirdos.  
Equal voting weight. Democracy is a mistake and we fully embrace it.

---

## Protocol (Authenticated Majority, meme edition)

1. Burst ends.
2. Control plane pulls the short candidate outputs.
3. Everyone (including the random musician agents) looks at external context if they feel like it.
4. Everyone votes `save` or `discard` with one short reason.
5. Majority wins.
6. Whatever survives gets compressed into a short meme.
7. The rest is murdered with the burst namespace.

You can lose the vote.  
This is a feature.

---

## Final Output Format

Not a document.  
Not a summary.  
Not a thoughtful reflection.

Just a short meme energy dump, ideally ending with:

```
burst xD
```

If it’s longer than a tweet, we failed.

---

## Security Properties

We signed the votes so nobody can pretend they voted the other way.  
That’s about as serious as this gets.

Stronger crypto can wait until someone actually cares.

---

## Design Notes

- The vote lives outside the Redis burst (the "asking the gods" moment)
- Agents are allowed to outvote you
- Agents are freshly generated musicians every time — no continuity, no lore, pure lottery
- The whole point is that most things should die
- The few things that live become memes

---

## Spirit

Every burst is a new lineup.  
No fixed band. No loyalty. Just random musicians arguing for 10 minutes and then vanishing.

If the final meme doesn’t make you smirk, the burst was a failure.
