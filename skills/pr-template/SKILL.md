---
name: pr-template
description: Structure for a pull request title and description - summary, changes, acceptance criteria, tests, review notes and risks. Use when opening a pull request.
---

# Pull request template

A repository's own template comes first: look for
`.github/pull_request_template.md` or a contributing guide and fill that in.
Use the structure below when there is none.

The description is for a reviewer who has not seen the work. It should let
them decide where to look closely and what they can trust.

## Title

Same form as a commit subject: `<type>: <description>`, imperative, about 70
characters. It should make sense in a list of merged changes.

## Description

```markdown
## Summary
What this changes and why, in two to four sentences. Lead with the effect on
the user or the system.

## Request and decisions
The request, and each decision with its reason, marked human or orchestrator.

## Changes
- <area>: <what changed>

## Acceptance criteria
| ID | Criterion | Status | Verified by |
|---|---|---|---|

## Tests
What was run, with counts and the result, and what was not run. New tests
added.

## Deviations
From the spec or the design, or "none".

## Documentation
Documents updated with this change, or "none affected".

## Review notes
Where a reviewer should look closely. Warnings from reviews that were
accepted as they are, and why.

## Risks and rollout
What could go wrong, how it would show, how to revert. Migrations,
configuration or feature flags needed. What was not verified.

## How to verify
Commands a reviewer can run.

## Out of scope and follow-ups

## Needs the owner's attention
Any change to AGENTS.md or other owner agreements, reversal of a recorded
decision, cost or free-tier effect, new dependency, or change to deployment
or security-relevant code. "None" if none.

## Known shortcuts
Deliberate shortcuts left in the code, each with its limit and when to
revisit it.

## References
Issue, run id, related pull requests.
```

## Rules

- **In gate mode** the description repeats the gate report the human approved.
- **Describe the whole branch**, not only the last commit. Read the full diff
  against the base branch before writing.
- **Report honestly.** A failing or skipped test, an unverified criterion or
  an open question is stated, not left out.
- **No narration of the process.** The reviewer needs the result and the
  reasons, not the order in which things were tried.
- **Keep it proportional.** A small change gets a short description; drop the
  sections that would be empty.
- **Screenshots or recordings** for anything visual, with their known limits.
- **One purpose per pull request.** If the summary needs "and also", consider
  splitting it.
- **No secrets, personal data or internal addresses** in the title, the
  description or attachments.

## Before opening

- The branch is up to date with the base branch and has no conflicts.
- Tests pass locally.
- The diff contains only what the description says.
- The pull request targets the right base branch and is never merged by its
  author without the review the project requires.
