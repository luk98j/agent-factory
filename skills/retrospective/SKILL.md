---
name: retrospective
description: Reviews a finished run - what looped, what the human corrected, what was missing - and identifies candidates for a new skill or agent once a pattern has repeated three times. Use at the end of every run, whether a pull request was opened, rejected or the run escalated.
---

# Retrospective

The purpose is to make the next run cheaper, not to describe this one. Read
`runs/<run-id>/state.json` and the stage results; do not rely on recollection.

## Questions

1. **Where did the run loop?** For each counter above zero: what was sent
   back, why, and could an earlier stage have caught it?
2. **What did the human change?** Feedback on the gate report or pull request, a rejection or a minor change is
   the strongest signal in the run. What would have had to be known earlier?
3. **What was missing?** Skills reported under `SKILLS_MISSING`, context
   agents asked for with `NEEDS_CONTEXT`, facts that had to be rediscovered.
4. **What was wasted?** Stages that produced nothing used, work that was
   redone, environment retries.
5. **What worked and should be kept?** Name it, so it is not optimized away.

Keep each answer to a line or two. An empty answer is fine.

## Finding candidates

A candidate is a pattern, not an incident. Look in `memory/INDEX.md` and the
matching run records (and in searchable memory when installed) for the same
thing happening before.

| Seen | Action |
|---|---|
| once | note it in the run record |
| twice | note it and mark it as a repeat |
| three times | propose a candidate to the human |

Decide what kind of candidate it is:

- **A skill**, when what was missing is knowledge: a checklist, a format, a
  convention, a procedure. This is the default.
- **A change to an existing agent or skill**, when the knowledge exists but is
  in the wrong place or incomplete.
- **A new agent**, only when the role needs its own decisions over several
  steps, its own context, parallel execution, or permissions no existing agent
  should have.

## Output

Write the answers into the run record (`memory/runs/<run-id>.md`) and report:

```
LOOPS: <counter, cause, where it could have been caught>
HUMAN_CORRECTIONS: <what and what it implies>
MISSING: <skills, context, facts>
KEEP: <what worked>
CANDIDATES:
  - kind: skill | change | agent
    name: <proposed name>
    evidence: <the three run ids>
    would_prevent: <one line>
```

Propose candidates; do not create them. Creation is the `factory` skill and
needs an explicit human accept.
