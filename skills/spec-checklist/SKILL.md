---
name: spec-checklist
description: Checklist for reviewing a specification before work starts - ambiguity, testability, contradictions, scope and edge cases - with the rule for when to return it. Use when approving or rejecting requirements and acceptance criteria.
---

# Specification checklist

A defect found here costs a question. The same defect found after
implementation costs a loop. Review against the original request, not only
against the spec itself.

## 1. Unambiguous

- Would two developers build the same thing from each criterion?
- Are there words that hide a decision: "appropriate", "as needed",
  "etc.", "should", "fast", "simple", "and/or"?
- Is every term used with one meaning throughout? Are names consistent with
  the code and the product?
- Are units, formats, time zones, rounding and ordering stated where they
  matter?

## 2. Testable

- Does each criterion say how it is verified?
- Can that check actually be run with the tools and data available?
- Is the expected result exact enough to fail?

## 3. Consistent

- Do any two criteria contradict each other?
- Does anything contradict how the system behaves today, without saying that
  the behavior is meant to change?
- Do the criteria agree with the stated scope?

## 4. Scope

- Is everything the request asked for covered by at least one criterion?
- Is anything included that the request did not ask for?
- Is "out of scope" stated for the things a reader would otherwise assume?

## 5. Edge cases

Check each that applies to the task:

- empty, single, maximum and over-maximum input;
- invalid, malformed and duplicated input;
- missing permission, expired session, wrong role;
- a dependency that is slow, unavailable or returns an error;
- two users or processes acting at once;
- existing data that does not fit the new rule; migration and rollback;
- repeated submission of the same request.

## 6. Feasible

- Does anything assume a capability the system does not have?
- Does a claim about current behavior match the code? Read it when it matters.

## Verdict

Return the spec only for a defect that would change what gets built or how it
is verified. Wording you would have chosen differently is not a defect; put it
under notes.

For each question you send back:

- tie it to a criterion id;
- make it answerable in one sentence;
- say what the two readings are, when the problem is ambiguity.

```
VERDICT: APPROVED | RETURNED
QUESTIONS:
  1. [AC-3] <question>  (reading A: … / reading B: …)
NOTES: <non-blocking observations, or none>
```
