---
name: factory
description: Procedure for creating or changing an agent or a skill in this orchestration, in the universal format that Claude Code and GitHub Copilot both load. Use only after the human has accepted a candidate from the retrospective or asked for one directly.
---

# Factory

Nothing is created without an explicit human accept of a named candidate.

## 1. Agent or skill

Default to a skill. Create an agent only if the role:

- makes its own decisions over several steps, or
- needs its own context, separate from the orchestrator's, or
- must run in parallel with other work, or
- needs permissions no existing agent should have.

If none applies, it is knowledge, and knowledge is a skill. Before creating
anything, check whether an existing agent or skill should be changed instead.

## 2. Creating a skill

Location: `skills/<name>/SKILL.md`. The name is lowercase with hyphens.

```markdown
---
name: <name>
description: <what it does and when to use it, in one or two sentences>
---
```

- The description decides whether the skill is ever loaded. State the trigger
  ("Use when ...") in it, in the words a task would use.
- Write what a capable reader would get wrong without the skill. Leave out
  what they would do correctly anyway.
- Explain the reason behind a rule, so it can be applied to cases the skill
  did not foresee.
- Prefer one worked example or a table over a paragraph.
- State the output format when another agent consumes the result.
- Keep it under about 150 lines. Split longer material into reference files
  beside `SKILL.md` and say when to read each.
- No project-specific facts in a general skill. Those belong in the project's
  own repository.

When the `writing-skills` skill is installed, follow its testing method.

## 3. Creating an agent

Location: `agents/<name>.agent.md`. One file serves both tools.

```markdown
---
name: <name>
description: <role, and when the orchestrator should dispatch it>
tools: [Read, Grep, Glob, Skill]
---
```

- Use only `name`, `description` and `tools` in the frontmatter. Other fields
  are not shared between the hosts.
- Give the minimum tools. Read-only (`Read, Grep, Glob, Skill`) unless the
  role must write; then say in the body exactly which files it may write.
- No `model` field: the agent inherits the session model.
- Follow the structure of the existing agents: role, operating contract,
  skills table, how it works, final message format.
- The final message starts with
  `STATUS: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED`.
- Worker agents never dispatch other agents and never write `state.json`.

## 4. Wire it in

A new piece that nothing references is never used.

- A new skill: add it to the skills table of every agent that should load it.
- A new agent: add it to the pipeline table in the orchestrator, with its
  place in the order, its loop and its counter.

## 5. Keep the documentation true

In the same change, update the agent and skill tables, the pipeline diagrams
and the chain map in every language the documentation is kept in.

## 6. Verify

- The frontmatter parses and `name` matches the file or folder name.
- `claude plugin validate agents` passes for agents.
- The new piece loads in each host that will use it.
- One small run exercises it.

## 7. Hand over

Report the files created or changed and what was verified. The change goes
through the normal human gate and is published as a pull request like any
other run.
