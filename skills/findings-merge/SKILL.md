---
name: findings-merge
description: Merges the findings of parallel reviews into one list - removes duplicates, checks each severity, and separates blocking findings that go back to the developer from warnings that go into the gate report (gate mode) and the PR description. Use after the reviews of a change return.
---

# Merging review findings

Several reviewers read the same diff independently, so their findings overlap
and their severities are not calibrated against each other. Your job is one
clean list the developer can act on and the human can read.

## Steps

1. **Collect.** Take every finding as written, with its source reviewer.
2. **Drop what cannot be acted on.** A finding without a location, or without
   a statement of what goes wrong, goes back to its reviewer as a question. Do
   not guess what it meant.
3. **Deduplicate.** Findings about the same lines and the same problem become
   one finding that lists all sources. Findings about the same lines but
   different problems stay separate.
4. **Check severity** against the rule below. You may lower a `blocking` that
   does not meet it and must say why. Never raise a `warning` on your own;
   ask the reviewer instead.
5. **Resolve conflicts.** When two reviewers want opposite things (for example
   caching for speed against freshness for correctness), do not pick. Record
   both and send the conflict to the human (an open conflict is an escalation), or to the architect when it
   is a design question.
6. **Order** blocking findings by what must be fixed first: correctness and
   security, then requirements, then the rest.

## Severity rule

A finding is `blocking` only if at least one is true:

- it breaks an acceptance criterion or a written project convention;
- it is a realistic way to lose, corrupt or expose data;
- it will fail or time out at the load the system is expected to carry;
- it leaves new risky logic (a branch, loop, parser, money, security) without
  a test.

Everything else is a `warning`: listed in the gate report (gate mode) and the PR description, never looped on.

## Routing

| Result | Next step |
|---|---|
| any blocking finding | developer, with only the blocking list; `code` counter +1 |
| warnings only | publisher, warnings listed in the gate report (gate mode) and the PR description |
| nothing | publisher |

Send the developer the finding itself (location, what goes wrong, fix
direction), never the reviewer's wider commentary. After the fix, re-run only
the reviews that raised blocking findings.

## Output

```
BLOCKING:
  - where: <file:line>  sources: <reviewers>
    what: <what goes wrong>   fix: <direction>
WARNINGS:
  - where: <file:line>  sources: <reviewers>   what: <...>
CONFLICTS: <pairs of findings that contradict, or none>
DOWNGRADED: <finding, and the reason, or none>
RETURNED_TO_REVIEWER: <findings that could not be acted on, or none>
```
