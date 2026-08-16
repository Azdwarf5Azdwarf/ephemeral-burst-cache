# Ephemeral Burst Cache (EBC)

> **In one sentence:** For about ten minutes you swap rhymes with three AI poets (and any friends you invite). Nothing you say is saved. At the end you get **one animated photo** — and that photo is the only thing kept.

---

## 🧭 Lost? Start here

**Read this box first. It is the map. Whenever you feel lost, come back to this box.**

Pick the line that matches you right now:

- 🆕 **I just want to try it** → do [1. Setup (once)](#1-setup-once), then [2. Run your first burst](#2-run-your-first-burst).
- 🔤 **A word confused me** (burst, uuid, TTL, poet, the adult) → [Words this project uses](#words-this-project-uses).
- 📋 **I forgot what a command does** → [All commands](#all-commands).
- 🛠️ **Something broke** → [If something breaks](#if-something-breaks).
- 📖 **I want the full story of what this is** → [What actually happens (the story)](#what-actually-happens-the-story).
- ❓ **Still lost** → read the sections below **in order, top to bottom**. You do **not** need to understand the poetic parts to use it. When in doubt, scroll back up to this box.

> **Rule of thumb: if you are ever unsure what to do next, the answer is in this README.** Start at this box and follow the links. You will not break anything by re-reading it.

---

## Words this project uses

Short, literal meanings. No metaphors in this table.

| Word | What it actually means |
|---|---|
| **burst** | One session. It lasts about 10 minutes, then everything about it is deleted automatically. |
| **uuid** | A long random ID string (looks like `a1b2c3d4-...`) that names one burst. You get it when you run `burst start`. Copy it — you need it for almost every other command. |
| **ttl** | "Time to live" — how many seconds a burst lasts before it deletes itself. Default is `600` (10 minutes). |
| **poet** | One of three AI characters (Frost, Cicada, Ember) that reply to you in rhyme. |
| **the adult** | A different AI that appears only once, at the very end, and names the mood. |
| **the photo** | The animated GIF you get at the end. It is the **only** file that survives a burst. |

---

## 1. Setup (once)

**Goal:** get the project ready to run. You only do this one time.

**Before you start, you need these installed:**

- Docker + Docker Compose
- Ruby 3.3
- ImageMagick
- Two API keys: `ANTHROPIC_API_KEY` and `XAI_API_KEY`

> Don't have those tools installed? Run `nix develop` — it provides Docker Compose, Ruby 3.3, Redis, and ImageMagick for you.

**Steps — do these in order:**

1. Start Redis (the temporary storage):
   ```bash
   docker compose up -d
   ```
2. Make your settings file:
   ```bash
   cp .env.example .env
   ```
3. Open the new `.env` file in a text editor and paste your two keys in:
   ```
   ANTHROPIC_API_KEY=your-key-here
   XAI_API_KEY=your-key-here
   ```
4. Install the Ruby libraries:
   ```bash
   bundle install
   ```
5. Check that everything works:
   ```bash
   ruby bin/healthcheck
   ```

**You should see:** the healthcheck finishing with no errors (it exits with code `0`).

**If it breaks:** go to [If something breaks](#if-something-breaks).

---

## 2. Run your first burst

**Goal:** talk to the poets and get a photo at the end.

**Before you start:** finish [1. Setup (once)](#1-setup-once) first.

**Steps — do these in order.** After step 1 you will have a **uuid**. Copy it, and paste it everywhere the steps show `<uuid>`.

1. Start a burst:
   ```bash
   ruby bin/burst start
   ```
   → this prints a **uuid**. Copy it now.
2. (Optional) Add a friend named Sam:
   ```bash
   ruby bin/burst join <uuid> Sam
   ```
3. Say something. The poets reply to you in rhyme:
   ```bash
   ruby bin/burst say <uuid> "the sky looks personally offended"
   ```
4. Repeat step 3 as many times as you like, until the 10 minutes run out.
5. Take the photo. This ends the burst:
   ```bash
   ruby bin/burst photo <uuid> us.jpg
   ```

**You should see:** a new file appear in the `photos/` folder, named like `photos/2026-08-15-delighted.gif`.

**If it breaks:** go to [If something breaks](#if-something-breaks).

> `us.jpg` should be a real photo of you and your friends, if you have one. If you skip it (leave it out), the whole picture is drawn from scratch instead.

---

## All commands

Every command is listed below. Anywhere you see `<uuid>`, paste the uuid you got from `burst start`. Square brackets `[ ]` mean that part is optional.

| Command | What it does |
|---|---|
| `ruby bin/burst start [ttl]` | Start a new burst. `ttl` is seconds (default `600`). Prints a uuid. |
| `ruby bin/burst invite <uuid>` | Print the code a friend needs in order to join. |
| `ruby bin/burst join <uuid> <name>` | Join someone else's burst, using your name. |
| `ruby bin/burst say <uuid> <text>` | Take your turn. The poets answer in rhyme. |
| `ruby bin/burst thread <uuid>` | Show the conversation so far. |
| `ruby bin/burst status <uuid>` | Show who is here and how much time is left. |
| `ruby bin/burst photo <uuid> [pic]` | End the burst and make the photo. `pic` is an optional image file. |
| `ruby bin/burst kill <uuid>` | Delete the burst right now. |
| `ruby bin/healthcheck` | Check that Redis, the API keys, and the photo tool all work. |

---

## If something breaks

Find your problem in the left column. Do the fix in the right column. If it is still broken after that, re-read [1. Setup (once)](#1-setup-once) from the top.

| What you see | What to do |
|---|---|
| `burst photo` fails and mentions ImageMagick | ImageMagick is not installed. Install it, or run `nix develop`. |
| Errors about Redis or "connection refused" | Redis is not running. Run `docker compose up -d`, then `ruby bin/healthcheck`. |
| Errors about API keys | Your `.env` is missing a key. Open `.env` and make sure both `ANTHROPIC_API_KEY` and `XAI_API_KEY` are filled in. |
| `command not found: bundle` | Ruby is not set up. Run `nix develop`, or install Ruby 3.3. |
| Anything else | Run `ruby bin/healthcheck` — it names the exact thing that is wrong. |

For deeper setup and deployment help, see **[DEPLOYMENT.md](DEPLOYMENT.md)**.

---

## What actually happens (the story)

*This part is the background and the mood. You do not need to read it to use the tool. If you just want to run it, everything you need is above.*

**You don't record a group chat. You take a photo after it has ended.**

A burst is ten minutes of talking nonsense in rhyme with three poets and
whoever you invited. Nothing you say is kept. When it's over, an adult opens
the door and asks what the hell you're all doing, everyone laughs it off, and
then you get a picture.

If you took a real photo of you and your friends, the poets get drawn into
it — they were there too. Your friends hold still, because they were actually
there; only the drawn ones move. That's the whole animation, and it's honest
about who was real.

The picture is the only thing that survives. Its filename says how the night
went, so a folder of these is browsable by feeling:

```
photos/2026-08-15-delighted.gif
photos/2026-08-11-restless.gif
```

### Who does what

| | |
|---|---|
| **Claude Haiku 4.5 ×3** | The poets. Haiku models that write sonnets, because the only rule is that we rhyme. |
| **Claude Opus 4.8** | The adult who opens the door. Doesn't rhyme, isn't impressed, and doesn't get the last word. |
| **Grok** | The camera. Doesn't talk. Only takes the picture. |

### The poets

| Poet | Voice |
|---|---|
| **Frost** | Stark and wintry — sees the cold truth and says it plainly |
| **Cicada** | Restless and loud — can hear the clock running out on all of this |
| **Ember** | Warm and wry — quietly funny, and always takes the last word |

Each replies with one ABAB quatrain, and **the rhyme carries between them**:
every poet after the first opens on the sound the previous one closed on. The
conversation rhymes as a group, not one voice at a time.

### The shape

```
        you  +  a friend you invited  +  3 poets
                          │
                          ▼
              rhyming quatrains, handed between voices
                          │
                          ▼
        Redis · no AOF · no RDB · hard TTL
                          │
                          ▼
        an adult opens the door: "Vad fan håller ni på med?"
        the room laughs it off and carries on
                          │
                          ▼
        the poets are drawn into your photo → one animated picture
                          │
                          ▼
              the poems die.  the picture stays.
```

See **[THE_PHOTO.md](THE_PHOTO.md)** for how the ending works.

---

## Core principles

- **Nothing is recorded** — no transcript, no summary, no saved note
- **Short by default** — ten minutes is already generous
- **We only rhyme** — and the rhyme is the group's, not each voice's
- **The adult says its piece once** — never written, and never obeyed
- **The picture is the memory** — and you can tell from it whether it was fun

## Status

Personal experiment. Play level. Not for production, not for your manager.

---

Built for people who think in bursts and then immediately forget they did.
