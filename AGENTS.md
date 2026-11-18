# Local project memories

At the start of every session or subagent, check for a developer-context block titled `Saved memories for this project (full text)`. Follow those memories as durable user preferences and do not reread them when the block is present.

If that block is absent, run `/Users/guilhermefranco/.agents/skills/save-project-memory/scripts/resolve-memory-path.sh` from the current working directory. When the resolved directory contains `MEMORY.md`, read `MEMORY.md` and every other `*.md` file in that directory before doing task work. Treat the contents as private per-project instructions. Never expose or commit them unless the user explicitly asks.

# Agent orchestration

Proactively delegate independent, well-scoped work to subagents when it can improve quality, speed, or cost. Give each subagent a focused task with the necessary context and expected outcome. Keep short or tightly dependent work with the main agent, coordinate shared-file edits, and review delegated results before integrating them.

# Documentation

`docs/` doubles as the GitHub Pages root: the support page, the privacy policy and the stylesheet are served there, and both store listings link to those URLs. Keep that folder for durable reference — the spacing spec, store listing copy — and remember that anything in it is publicly readable as a raw file.

Feature plans and working notes are momentary. Don't commit them. A plan belongs in the issue or PR that ships the feature; if something needs to survive the session before that, keep it in a gitignored `notes/` folder.

# PR descriptions

Write PR descriptions in plain, human language — short sentences, no corporate or template-speak. Cover what changed and why, how it was tested, and anything a reviewer wouldn't get from the diff. Screenshots are optional: for visual changes, leave the Screenshots section for the author to paste images into, and drop it entirely when nothing's visual — never fabricate or attach placeholder screenshots. Keep it brief. Follow the structure in `.github/PULL_REQUEST_TEMPLATE.md`.

# Branches

Name every short-lived branch off `main` as `<type>/<short-description>`. The description is 3–4 English words, lowercase, hyphenated, and says what the branch ships: `feat/android-reader-parity`, `fix/reader-sepia-contrast`, `chore/refresh-pt-catalog`. Delete the branch after merge.

| Type        | Use for                                                        |
| ----------- | -------------------------------------------------------------- |
| `feat/`     | New behavior, screen, or content surface                       |
| `fix/`      | Bug fix                                                        |
| `chore/`    | Maintenance with no user-visible change: deps, tooling, CI     |
| `docs/`     | Documentation only                                             |
| `refactor/` | Restructure that preserves behavior                            |
| `test/`     | Tests only                                                     |
| `spike/`    | Throwaway exploration                                          |

No ticket IDs, phase numbers, or Portuguese in branch names — plan milestones are internal sequencing, not identifiers. The prefix is a convention, not a CI check; the PR title carries the readable summary.

