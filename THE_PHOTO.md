# The Photo

(the part where everyone stands still for a second)

Nothing said during a burst is kept. There is no transcript, no summary, no
saved note. What you get at the end is a picture, the way you'd get one at
the end of an actual evening.

---

## How it ends

1. The burst ends (TTL fires, or you run `burst photo <uuid>` before it does).
2. **The judge speaks.** Claude Opus 4.8 reads the whole thing and says
   whatever it wants — as long or short as it likes, warm or sharp as it
   deserves. It is the only participant not bound to rhyme.
3. **You hear it once.** ElevenLabs speaks the verdict aloud. It is never
   written to disk. If no audio player is available it prints once instead —
   still unsaved, still gone when you close the terminal.
4. On its way out the judge names the **mood** and describes the **scene**.
5. **The picture is taken.** Grok draws the three poets, four times over,
   each frame a moment apart.
6. If you handed in a real photo, the poets are keyed out of their flat
   background and composited into it. If you didn't, the whole scene is drawn.
7. The frames become one GIF in `photos/`. Everything else dies with the TTL.

---

## Why the poets are drawn in

At the end of a real hangout you ask someone to take a picture of you and
your friends. That picture is real — real faces, real light, a real place.

The poets weren't real, but they were there. So they get drawn into it, the
way a cartoon gets pasted into a photograph: bold outlines, obviously not
part of the scene, obviously present anyway.

**Only the drawn ones move between frames.** Your friends hold still, because
they actually held still. The poets shimmer and shift because they were never
there to begin with. That's the animation, and it isn't a compositing
artifact — it's the picture telling the truth about who was real.

> Expect rough edges. The chroma key leaves haloes, and the poets won't match
> your lighting. Good. A clean composite would be a lie.

---

## The filename is the memory

```
photos/2026-08-15-delighted-4laughs.gif
```

Date, mood, and the number of times someone actually laughed — counted from
what ElevenLabs heard, not guessed by a model. The mood comes from the judge;
the laughs come from the room.

This is the point. You should be able to open that folder months later and
tell, without opening a single file, which nights were good ones. The album
is the memory. No individual picture has to carry it.

A photo is never silently overwritten — a second burst on the same day with
the same mood gets a short suffix instead.

---

## Participants

- You
- Anyone you invited (`burst join <uuid> <name>`)
- **Frost**, **Cicada**, and **Ember**

Everyone who joined is named in the picture's prompt. A group photo needs a
group.

---

## Spirit

Most things should die. You don't need the words back — you were there. What
you want later is a picture where everyone looks like they were having the
kind of night you remember having.

Ten minutes of rhyming in, one picture out, nothing in between is kept.
