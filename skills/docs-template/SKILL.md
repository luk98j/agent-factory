---
name: docs-template
description: Structures and rules for technical documentation - choosing the document type, standard sections, where documents live, and how to keep them in step with code changes. Use when writing new documentation or updating existing documentation after a change.
---

# Documentation template

Pick the document type by what the reader is trying to do. Mixing types in
one document is the most common reason documentation is hard to use.

## Types

| Type | Reader wants to | Shape |
|---|---|---|
| Tutorial | learn by doing a first task | numbered steps with expected results; one path, no options |
| How-to guide | get a specific task done | prerequisites, steps, verification; assumes the basics |
| Reference | look up a fact | complete, consistent, structured like the thing described |
| Explanation | understand why | background, design decisions, tradeoffs, alternatives rejected |

## Standard sections

**README**: what it is in one paragraph; quick start that works when copied;
main usage; configuration; links to deeper documents; license.

**Component or module document**

```markdown
# <Name>

## Purpose
What it is for and what it is not for.

## How it works
The flow, with a diagram when it has more than three steps.

## How to use it
The common case, with a runnable example.

## Configuration
| Setting | Default | Effect |

## Failure modes and limits
What can go wrong, how it shows up, what to do.

## Where the code lives
Entry points and the files to read first.
```

**Decision record**: context, decision, alternatives considered, consequences.
Dated, and never rewritten; a later decision supersedes it.

**Changelog entry**: what changed for the user, grouped as added, changed,
fixed, removed; breaking changes first.

## Where documents live

Follow the repository's existing layout. When there is none: `README.md` at
the root, everything else under `docs/`, one topic per file, file names in
lowercase with hyphens. Keep a document next to the code only when it
describes just that code.

## Writing rules

- Lead with what the reader needs; background comes after.
- Every claim is grounded in the source. Name the file or symbol so it can be
  checked. Mark what you could not verify.
- Describe what is, not what is planned.
- Examples are complete and runnable; show the expected output.
- One term per concept, the same one the code uses.
- A table for comparisons, a list for steps, a diagram for flows.
- State the version or date a document applies to when behavior changes
  between versions.

## Keeping documents in step with a change

1. From the diff, list what changed for a reader: behavior, interfaces,
   configuration, commands, limits, structure.
2. Search for every place that mentions it: README files, the docs folder,
   diagrams, examples, the changelog, comments that document public
   interfaces.
3. Update exactly those places, keeping each document's structure and voice.
4. Add a section only when the change introduces something with no home.
5. Remove descriptions of what no longer exists; do not leave them marked as
   old.
6. Documents kept in several languages are updated in all of them, in the
   same change.
7. If nothing is affected, say so and list where you looked.
