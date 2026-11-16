---
name: test-strategy
description: How to decide what to test and at which level - unit, integration or end-to-end - how to map tests to acceptance criteria, and how to classify a failure. Use when planning, writing or running tests for a change.
---

# Test strategy

Tests exist to show that each acceptance criterion holds and to catch the
change that breaks it later. Coverage numbers are a side effect.

## Choosing the level

Use the lowest level that can prove the criterion.

| Level | Proves | Use when |
|---|---|---|
| Unit | one piece of logic in isolation | branches, calculations, parsing, validation, state transitions |
| Integration | pieces working together across a real boundary | database queries, HTTP handlers, message consumers, file access, configuration |
| End-to-end | a user-visible flow through the whole system | the few flows whose failure would be noticed first by users |

Signs the level is wrong: a unit test that needs many mocks is really testing
an integration; an end-to-end test that checks a calculation should be a unit
test.

## What to test

- Every acceptance criterion maps to at least one test or check.
- New logic with a branch, a loop, a parser, money or security gets a test
  even when no criterion names it.
- For each criterion, the failure path as well as the success path.
- Boundaries: empty, one, maximum, just over maximum.
- A bug fix starts with a test that reproduces the bug and fails for that
  reason.

What not to test: the framework, the language, trivial accessors, and
implementation details that a refactor would change without changing behavior.

## Good tests

- Assert on behavior the caller can observe, not on which internal method was
  called.
- One reason to fail per test; the name states the behavior and the condition.
- Arrange, act, assert, visibly separated.
- Independent of other tests and of execution order; each creates the data it
  needs.
- Deterministic: no real clock, random values or network unless that is what
  is under test. Wait for a condition, never for a fixed time.
- Mock only at boundaries you do not own. A test that asserts on its own mock
  proves nothing.
- Output is clean. Warnings in a passing run are worth reporting.

## What to run

| Moment | Run |
|---|---|
| while changing code | the focused tests for what is being changed |
| after a fix | the tests touched by the change |
| before publishing | the full suite, once |

## Classifying a failure

The class decides where the run goes next, so get it right before reporting.

| Class | Meaning | Check |
|---|---|---|
| `implementation` | the code does not do what the criterion says | the test is correct and fails for the stated reason |
| `spec_unclear` | the criterion can be read two ways or cannot be checked | you can state both readings |
| `environment` | timeout, missing dependency, unavailable service | the same test passes when the environment is fixed; retry at most twice |

A test that fails only sometimes is not an environment error until shown to
be one. Find out which condition makes it fail.

## Reporting

Per criterion: `pass` with the command and the passing output, or `fail` with
the command, the output and expected against actual. No evidence means `fail`.
