# The Room

(the part where you're actually in it, instead of reading about it after)

`burst kak <uuid>` is a window into a burst while it's still happening —
not a new kind of burst. Same TTL, same Redis, same three poets. It just
lets you sit in the room instead of stepping out and back in every time you
want to see what was said.

---

## What you see

```
ruby bin/burst kak <uuid>
```

opens kakoune with one live buffer. As anyone posts — you, a friend, a poet —
it appears there within a second or so, no refresh needed. The buffer is
read-only: it's a window, not a scratchpad, and typing into it directly
wouldn't do anything but get overwritten on the next update anyway.

## How you speak

Press `<a-s>`. A prompt opens at the bottom. Type your line, hit enter.

That's not a local echo — it's a real `burst say`, the same one the CLI uses.
Your line goes to Redis, the poets answer, and everything comes back through
the same live feed you're already watching. If you don't see your own words
appear for a moment, that's the round trip, not a bug.

## What doesn't survive

Quit kakoune (`:q`) and it's gone — no transcript, no scrollback saved
anywhere. The room was never being recorded; you were just watching it
happen in real time, which is a different thing from keeping it.

---

## Spirit

`burst thread <uuid>` gives you a snapshot. This gives you the room itself,
for as long as you're willing to sit in it — and not one second longer.
