---
name: style-checklist
description: Stack-independent checklist for reviewing a change for scope, simplicity, readability, conventions, tests and comments, with a severity rule. Use when reviewing a diff for code style and maintainability.
---

# Style checklist

The reference is the surrounding code and the project's written conventions,
not personal preference. A project's own style skill, when present, overrides
anything here.

## Scope

- Does every changed line trace to the task?
- Drive-by changes: refactors, renames, reformatting or dependency bumps
  unrelated to the task.
- Features, options or parameters nobody asked for.
- Unrelated code or comments removed or rewritten.

## Simplicity

- An abstraction, interface, base class or configuration option with a single
  use.
- New code that duplicates something the codebase, the standard library or an
  installed dependency already provides.
- A new dependency for something a few lines would do.
- Error handling for situations that cannot occur.
- Dead code, unused parameters or imports introduced by the change.
- Could the same behavior be achieved with noticeably less code?

## Conventions

- Naming, file and folder layout, and layering follow what the codebase
  already does.
- Errors are handled the way neighboring code handles them.
- Public interfaces are consistent with existing ones.

## Readability

- Names say what a thing is or does; no abbreviations a newcomer would have
  to look up.
- Functions that do several things, or grew past what fits on a screen in
  this change.
- Nesting deep enough that early returns would make it clearer.
- Unexplained literal values that carry meaning.
- A clever one-liner that needs decoding.

## Tests

- New logic with a branch, loop, parser, money or security has a test.
- Tests assert on behavior, not on mocks or on implementation details.
- Test names state the behavior and the condition.

## Comments

- A comment explains why, when the code cannot show it. Comments that restate
  the code are noise.
- A deliberate shortcut is marked with its limit and when to revisit it.
- No commented-out code, debug output or leftover task notes.

## Leave to tools

Whitespace, quote style, import order and anything else a formatter or linter
enforces. Do not report these by hand.

## Severity

| Severity | Use when |
|---|---|
| `blocking` | violates a written project convention, adds unrequested scope, or leaves risky logic untested |
| `warning` | readability and maintainability suggestions |

Each finding: `file:line`, what is there, why it matters, the fix direction.
A preference is not a finding.
