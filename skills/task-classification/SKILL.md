---
name: task-classification
description: Decides which pipeline a request belongs to - dev, content, docs or design - and when to split it or ask first. Use at the start of every run, before any agent is dispatched.
---

# Task classification

Pick the pipeline by what the request must produce, not by the words it uses.

## Decision order

Ask these in order and stop at the first yes:

1. **Is the deliverable a decision about how something looks or behaves for a
   user, before it is built?** → `design`. Signals: design, mockup, wireframe,
   prototype, UI, UX, layout, look and feel, redesign, design system, `/design`.
2. **Does the deliverable change what the software does?** → `dev`. Signals:
   add, fix, implement, refactor, migrate, bug, endpoint, test failure.
3. **Is the deliverable text whose reader is outside the project** (customers,
   followers, a newsletter list, the company)? → `content`.
4. **Is the deliverable a description of something that already exists** for
   people who use, operate or change it? → `docs`.

## Cases that look alike

| Request | Type | Why |
|---|---|---|
| "Document the new endpoint we are about to build" | dev | the endpoint does not exist yet; docs sync is part of the dev run |
| "Write release notes for customers" | content | the reader is outside the project |
| "Write a changelog entry" | docs | describes what exists, for people working with the project |
| "Make the settings page look better" | design | the outcome is a decision about appearance |
| "Implement this mockup" | dev | the design decision is already made |
| "Fix the typo in the README" | none | trivial; no run needed |

## Mixed requests

Split a request that needs more than one type into separate runs and order
them by dependency: design before dev, dev before content about the feature,
dev before docs about it. Tell the human the split before starting.

## When to ask

Ask one question, and only when the answer changes the pipeline or the
deliverable:

- the audience is unclear and decides between `content` and `docs`;
- "design" could mean visual design or technical design (the second is the
  architect's stage inside `dev`);
- the request names a result but not whether it should be built or only
  proposed.

Do not ask about details the first agent of the pipeline will clarify anyway.

## Before the analyst

Run this checklist on every request, before any agent is dispatched:

- What already exists outside the repo (ChatGPT tasks, cloud settings,
  accounts) that could duplicate or conflict?
- What must the owner do by hand, and in which order (deploy, refresh the
  plugin tool list, create tasks)?
- Does it touch cost or the free tier?
- Does it depend on a pending merge?
- Are all placeholders in a pasted template filled?

Result: ask ALL open owner questions in ONE message at the start (at most 4,
each with a recommended default, phrased so that "ok" suffices). After that, no
further question rounds except the escalations listed in the orchestrator.

## Output

```
TYPE: dev | content | docs | design | none
REASON: <one line>
SPLIT: <further runs in order, or none>
QUESTION: <one question, or none>
```
