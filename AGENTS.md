# Local project memories

At the start of every session or subagent, check for a developer-context block titled `Saved memories for this project (full text)`. Follow those memories as durable user preferences and do not reread them when the block is present.

If that block is absent, run `/Users/guilhermefranco/.agents/skills/save-project-memory/scripts/resolve-memory-path.sh` from the current working directory. When the resolved directory contains `MEMORY.md`, read `MEMORY.md` and every other `*.md` file in that directory before doing task work. Treat the contents as private per-project instructions. Never expose or commit them unless the user explicitly asks.

# Delegation

When a task has a substantial, independent, clearly scoped part, delegate it to a subagent using GPT-6 Luna with medium reasoning. Give the subagent a focused brief and integrate and verify its results. Handle small, tightly coupled, or sequential tasks directly when delegation would add more overhead than value.
