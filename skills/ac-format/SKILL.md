---
name: ac-format
description: Format and quality rules for acceptance criteria - one observable condition each, with an id and a stated way to verify it. Use when writing or checking requirements for a dev, design or content task.
---

# Acceptance criteria format

An acceptance criterion is a statement someone can check and answer with yes
or no. It describes an observable result, not an implementation.

## Format

| ID | Criterion | Verified by |
|---|---|---|
| AC-1 | Given <starting state>, when <action>, then <observable result> | <test level or check> |

- **ID**: `AC-<n>`, stable for the whole run. Never renumber; a removed
  criterion leaves a gap.
- **Criterion**: given / when / then. One condition per row.
- **Verified by**: how it will be checked: a unit, integration or end-to-end
  test, a command and its expected output, or a manual check with exact steps.

## Rules

1. **Observable.** The result is something a user, a caller or a test can
   see. "Uses a cache" is not; "a second request within 60 s returns without
   calling the upstream service" is.
2. **One condition.** If the sentence needs "and" between two results, it is
   two criteria.
3. **Exact.** Replace "fast", "user-friendly", "secure", "properly" with a
   number, a named behavior or a named rule.
4. **Independent of the solution.** Say what must be true, not which class,
   library or layout achieves it, unless the request fixes it.
5. **Negative paths included.** Invalid input, missing permission, empty and
   maximum sizes, failure of a dependency: each one that matters gets a row.
6. **Traceable.** Every criterion follows from the request. A criterion
   nobody asked for is scope creep, however sensible it is.

## Examples

| Weak | Why | Better |
|---|---|---|
| The form validates e-mail | not observable, no failure path | Given an address without `@`, when the form is submitted, then it is not sent and the field shows "Enter a valid e-mail address" |
| Search is fast | no number | Given 10 000 records, when a user searches by name, then results appear in under 300 ms at the 95th percentile |
| Admins can manage users | several conditions | one row each for create, deactivate, change role |
| The design looks modern | not checkable | Given a 360 px wide screen, when the page loads, then no content scrolls horizontally and all touch targets are at least 44 px |

## For design and content tasks

Use the same table. The "then" describes what the reader or user can do or
perceive: the states and breakpoints covered, the contrast level met, the
message that must be present, the length limit kept.

## Before handing over

- Every criterion can be answered yes or no.
- Every criterion has a way to verify it that can actually be run.
- No two criteria contradict each other.
- Anything still open is listed as a question, not hidden in vague wording.
