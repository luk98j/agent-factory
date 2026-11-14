---
name: platform-rules
description: How to adapt one master text to different publishing platforms - social posts, newsletter, blog, release notes, internal announcement - by changing form while keeping the message and facts. Use when writing or adapting content for a specific platform.
---

# Platform rules

Adapting means changing form: length, structure, opening, formatting. The
message and the facts stay exactly as in the master text and the brief.

## Limits change; check them

Character limits, link handling, formatting support and ranking behavior are
set by each platform and change over time. Do not rely on remembered numbers.
Use the limits given in the brief; when the brief gives none, state the limit
you assumed so it can be checked.

## What each kind of platform rewards

| Platform kind | Reader's situation | Shape |
|---|---|---|
| Short social post | scrolling; decides in the first line | one idea; the point in the opening words; link or call to action at the end |
| Professional network post | scanning for something relevant to their work | a concrete opening line, short paragraphs, one takeaway |
| Thread or carousel | committed after the first item | the first item stands alone; each following item carries one point |
| Newsletter | chose to receive it; opens by subject line | subject line states the benefit; the most important item first; scannable sections |
| Blog or article | came with a question, often from search | title says what the reader gets; answer early; headings that work as an outline |
| Release notes | wants to know what changed for them | grouped by change type; user-visible effect first; breaking changes on top |
| Internal announcement | needs to know whether to act | what is changing, who is affected, what to do and by when, in that order |
| Product or interface text | in the middle of a task | as few words as possible; the action named by its verb |

## Rules for every platform

- **Open with the point.** The first line must work without the rest.
- **One call to action.** Two compete; the reader does neither.
- **Format natively.** Use only formatting the platform renders. Markdown
  shown as raw symbols is worse than plain text.
- **Links.** One primary link. Place it where the platform shows it well.
- **Tags and mentions** only when they are relevant and the brief allows
  them; a few specific ones rather than many general ones.
- **Images and media.** Say what is needed and provide a text alternative.
- **Accessibility.** Plain words, no text locked inside images, capitals at
  the start of each word in multi-word tags, sparing use of emoji.
- **No new facts.** A shorter version may leave facts out. It never adds or
  sharpens them.

## Adapting

1. Read the master text and write its message in one sentence.
2. Decide what this platform's reader needs first.
3. Cut to fit the form. Remove whole points rather than compressing every
   sentence.
4. Rewrite the opening for this platform; openings rarely transfer.
5. Check the result against the limit, the brief's criteria and the facts in
   the master text.

## Output

```
PLATFORM: <name>
LIMITS_USED: <limit and where it came from: brief | assumed>
TEXT: <the adapted text>
LEFT_OUT: <points from the master not included>
MEDIA_NEEDED: <what and its text alternative, or none>
```
