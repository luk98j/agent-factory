---
name: commit-conventions
description: Conventions for commit messages and branch names - conventional commit types, subject and body rules, what belongs in one commit, and checks before committing. Use when creating a commit or a branch.
---

# Commit conventions

A repository's own conventions come first. Read the recent history
(`git log --oneline -20`) and any contributing guide, and match them. Use the
rules below when the repository has none.

## Message format

```
<type>: <description>

<optional body>
```

| Type | Use for |
|---|---|
| `feat` | a new capability for the user |
| `fix` | a bug fix |
| `refactor` | a change in structure with no change in behavior |
| `perf` | a change that improves performance |
| `test` | adding or correcting tests only |
| `docs` | documentation only |
| `chore` | maintenance: dependencies, configuration, tooling |
| `ci` | build and pipeline configuration |

Pick the type by the effect on the user of the code. A bug fix that needed a
refactor is a `fix`.

## Subject line

- Imperative mood, as if completing "This commit will …": "add", "fix",
  "remove".
- Lowercase after the type, no full stop, about 70 characters at most.
- Says what changed in terms a reader of the log understands without opening
  the diff. "fix: bug" and "chore: updates" say nothing.

## Body

Add one when the subject cannot carry the reason. Explain why the change was
made and anything a future reader would not guess from the diff: the cause of
a bug, a tradeoff taken, a follow-up left. Do not narrate the diff.

Reference an issue or a run id on its own line at the end when there is one.
A change that breaks existing users says so explicitly, with what they must
do.

## What goes into one commit

- One logical change. A reviewer should be able to describe it in one
  sentence.
- Tests and documentation for a change go in the same commit as the change.
- Unrelated fixes noticed along the way go in their own commit, or are
  reported instead.
- Formatting-only changes are separate from behavior changes.

## Branch names

`<type>/<short-description>` in lowercase with hyphens, for example
`feat/email-validation` or `fix/session-expiry`. Include a run or issue id
when the project uses them.

## Before committing

- Stage files by name. Never stage everything blindly.
- Read the staged diff. Look for secrets, credentials, personal data, local
  paths, debug output and files that are not part of the change.
- Tests for the change pass.
- Never skip hooks or checks to get a commit through; fix what they report.
- Never commit directly to the default branch, force-push shared branches or
  rewrite published history.
