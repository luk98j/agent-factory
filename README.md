# Agent Factory

English | [Polski](README.pl.md)

A set of 14 agents that work as one pipeline in **Claude Code** and
**GitHub Copilot**. One orchestrator plans and delegates, specialized agents do
the work, and nothing is published before a human accepts it.

Each agent is a single file that both tools load unchanged. The agents are
generic: knowledge about a project (stack, conventions, checklists) comes from
skills.

## The chain

```mermaid
flowchart LR
  U([Task]) --> O{{orchestrator}}
  O -->|dev| A1[analyst] --> SR[spec-reviewer] --> AR[architect] --> D[developer] --> T[tester]
  T --> RS[review-security] & RP[review-performance] & RY[review-style]
  RS & RP & RY --> DSY[docs-writer: sync] --> G{Human gate}
  O -->|content| BW[brief-writer] --> CW[copywriter] --> CA[copywriter × platform] --> G
  O -->|docs| DW[docs-writer] --> AD[architect: review] --> G
  O -->|design| A2[analyst] --> DS[designer] --> G
  G -->|accept| P[publisher] --> PR([Pull request])
  G -.->|reject with a note| O
```

An interactive version of this map, with every agent's role, tools and skills,
is in [docs/agent-chain.html](docs/agent-chain.html) (open it locally in a
browser).

## Pipelines

| Pipeline | When | Stages | Loops |
|---|---|---|---|
| **dev** | a code change | analyst → spec-reviewer → architect → developer → tester → three reviews in parallel → docs-writer (sync) → gate → publisher | spec unclear → analyst (`spec` ≤ 3); failing test or blocking finding → developer (`code` ≤ 3); environment error → 2 retries |
| **content** | text for an audience | brief-writer → copywriter → copywriter per platform (parallel) → gate → publisher | gate → author (`revision` ≤ 3) |
| **docs** | describing what exists | docs-writer → architect (review) → gate → publisher | architect → docs-writer (`revision` ≤ 3) |
| **design** | "design", mockup, UI/UX, redesign, `/design` | analyst → designer → gate → publisher | gate → designer or analyst (`revision` ≤ 3) |

When a counter runs out, the run stops and waits for a human.

## Agents

| Agent | Role | Tools | Writes | Skills |
|---|---|---|---|---|
| `orchestrator` | classifies the task, delegates stages, counts attempts, keeps state and memory | all (inherited) | `runs/`, `memory/` | `task-classification`, `findings-merge`, `retrospective`, `factory`, `karpathy-guidelines`, `dispatching-parallel-agents`, `mem-search` |
| `analyst` | requirements and testable acceptance criteria | Read, Grep, Glob, Skill | nothing | `ac-format`, `brainstorming` |
| `spec-reviewer` | approves the spec or returns it with questions | Read, Grep, Glob, Skill | nothing | `spec-checklist` |
| `architect` | technical design and plan; reviews docs against the code | Read, Grep, Glob, Skill | nothing | `architecture-patterns`, `stack-and-style`, `writing-plans`, `ponytail` |
| `developer` | implements the plan test-first; the only agent that edits product code | Read, Grep, Glob, Edit, Write, Bash, Skill | code | `stack-and-style`, `ponytail`, `test-driven-development`, `systematic-debugging`, `security-checklist`, `verification-before-completion` |
| `tester` | checks every acceptance criterion with evidence | Read, Grep, Glob, Bash, Edit, Write, Skill | test files | `test-strategy`, `stack-and-style`, `webapp-testing`, `verification-before-completion` |
| `review-security` | independent security review of the diff | Read, Grep, Glob, Skill | nothing | `security-checklist`, `stack-and-style` |
| `review-performance` | independent performance review of the diff | Read, Grep, Glob, Skill | nothing | `performance-checklist`, `stack-and-style` |
| `review-style` | conventions, readability, simplicity, scope | Read, Grep, Glob, Skill | nothing | `style-checklist`, `stack-and-style`, `ponytail-review` |
| `designer` | user flows, mockups, tokens, handoff | Read, Grep, Glob, Edit, Write, Skill | `runs/<id>/design/` | `design-system`, `brand-guidelines`, `frontend-design`, `web-artifacts-builder`, `canvas-design`, `theme-factory`, `ponytail` |
| `brief-writer` | content brief: goal, audience, message | Read, Grep, Glob, Skill | nothing | `brief-format`, `brand-guidelines`, `brainstorming` |
| `copywriter` | master text and per-platform adaptations | Read, Grep, Glob, Skill | nothing | `platform-rules`, `brand-guidelines`, `internal-comms`, `doc-coauthoring` |
| `docs-writer` | writes new docs; keeps docs in step with code changes | Read, Grep, Glob, Edit, Write, Skill | documentation | `docs-template`, `doc-coauthoring`, `stack-and-style` |
| `publisher` | branch, commit, pull request, only after a recorded human accept | Read, Grep, Glob, Bash, Skill | git | `commit-conventions`, `pr-template`, `finishing-a-development-branch` |

A missing skill never blocks an agent: it falls back to a default checklist in
its own file and reports the gap.

## Shared parts

| Part | What it does |
|---|---|
| **State** | `runs/<run-id>/state.json` is the single source of truth. Only the orchestrator writes it. |
| **Human gate** | Every pipeline stops before publication. Accept, reject with a note, or ask for a minor change. |
| **Memory** | After every run the orchestrator writes what was learned to `memory/runs/<run-id>.md` and reads matching records at the next start. [claude-mem](https://github.com/thedotmack/claude-mem) adds search across sessions. |
| **Docs move with the change** | Before the gate, `docs-writer` updates the documents a code change makes outdated. They ship in the same pull request. |
| **Observation** | [Claude Code Agent Monitor](https://github.com/hoangsonww/Claude-Code-Agent-Monitor) shows the run tree; every dispatch is named `[run-id] agent #attempt`. |
| **Working rules** | [Karpathy guidelines](https://github.com/multica-ai/andrej-karpathy-skills) for the orchestrator, [Ponytail](https://github.com/DietrichGebert/ponytail) for the smallest complete change, the [Superpowers](https://github.com/obra/superpowers) contract between agents. |

## Quick start

Install the agents for every project (copies them to `~/.claude/agents/` and
`~/.copilot/agents/`):

```bash
git clone https://github.com/luk98j/agent-factory.git && cd agent-factory
scripts/install.sh
```

Start a session with the orchestrator as the main agent, inside the project
you want to work on:

```bash
claude --agent orchestrator
```

```bash
copilot --agent orchestrator
```

Then describe the task in plain language. The orchestrator picks the
pipeline:

- "Add e-mail validation to the sign-up form" → dev
- "Design the login screen" or `/design login screen` → design
- "Describe how the payments module works" → docs
- "Write a LinkedIn post about the new feature" → content

The run stops at the gate with a report. A pull request is opened only after
you accept. The publisher needs a git repository with a remote and an
authenticated `gh`.

## Keeping the repository and your agents in sync

| Direction | Command | What it does |
|---|---|---|
| repository → user folders | `scripts/install.sh` | copies `agents/*.agent.md`; touches nothing else in the targets |
| user folder → repository | `scripts/sync-back.sh` | creates the branch `sync/agents-<timestamp>` and commits the agents that changed |

Useful options:

- `scripts/install.sh --dry-run` shows what would change.
- `scripts/sync-back.sh --push` also pushes the branch and opens a pull request
  with `gh`.
- `scripts/sync-back.sh --from copilot` reads from the Copilot folder instead
  of the Claude one.
- `scripts/sync-back.sh --add my-agent` brings in an agent the repository does
  not track yet.

Before committing, `sync-back.sh` scans the changed files for home paths,
e-mail addresses and credential formats, and stops if it finds any.

The scripts are Bash and run on macOS, Linux, WSL and Git Bash. Override the
target folders with `CLAUDE_AGENTS_DIR` and `COPILOT_AGENTS_DIR`.

## Documentation

- [docs/ORCHESTRATION.md](docs/ORCHESTRATION.md): the full description:
  format, contract between agents, loops, state, memory, skills, dependencies,
  known limits.
- [docs/agent-chain.html](docs/agent-chain.html): the interactive map.

## Status

The agent definitions pass `claude plugin validate`. The format follows the
Claude Code and GitHub Copilot documentation; a full run in each tool is still
to be verified. Known limits are listed in
[docs/ORCHESTRATION.md](docs/ORCHESTRATION.md#9-limits-and-things-to-verify).

## License

[Apache License 2.0](LICENSE).
