# Godogen Source Repo

This repository is not a published game repo. It is the source that `publish.sh` renders into a runtime game repo for a chosen engine, host agent, and delivery mode.

## Source Layout

- `prompts/` — engine-agnostic runtime text:
  - `runtime.md` — the process preamble for the runtime manifest
  - `oneshot.md`, `interactive.md` — the delivery-regime blocks
- `asset-gen/` — the asset-generation skill (CLI tools + docs), the one skill every published repo carries
- `engines/babylon.md`, `engines/godot.md`, `engines/bevy.md` — per-engine guides (stack, project sketch, capture recipe, silent-failure traps)
- `publish.sh` — renders a runtime repo with `--engine {godot,bevy,babylon}`, `--agent {claude,codex}`, `--mode {oneshot,interactive}`
- `scripts/` — render helpers: `render_dir.py` (token substitution), `generate_codex_metadata.py` (Codex `openai.yaml`)

Engine, host agent, and mode are all publish-time render choices, not source-tree splits.

## Source vs Runtime

A published repo is docs plus one skill:

- The runtime manifest (`CLAUDE.md` for Claude, `AGENTS.md` for Codex) is assembled from `prompts/runtime.md` + the chosen `prompts/<mode>.md`.
- `engines/<engine>.md` renders to `<engine>.md` (e.g. `babylon.md`) at the repo root — the guide the manifest points to.
- `asset-gen` renders to `.claude/skills/` (Claude) or `.agents/skills/` (Codex); Codex `agents/openai.yaml` is generated from its `SKILL.md` frontmatter.
- Do not create or maintain `.claude/skills/` or `.agents/skills/` in this source repo.

The agent builds everything else — project scaffold, capture tooling, scene wiring — from the engine guide. The runtime repo ships no project template.

## Skills

Every published repo carries exactly one skill: **asset-gen** (image / GLB / rigged-character / animated-sprite generation, shared across engines). Engine knowledge lives in the engine guide, not in a skill.

## Editing Rules

- Engine-specific guidance stays in `engines/<engine>.md`. Engine-agnostic process stays in `prompts/runtime.md` and `prompts/{oneshot,interactive}.md`.
- Asset tooling and docs stay in `asset-gen/`.
- If you change the asset skill's user-facing purpose, update its `SKILL.md` frontmatter. Do not hand-edit generated `agents/openai.yaml`.
- Don't give obvious guidance. The agent is a highly capable LLM, and the deliverable (a recorded video, or a live URL the user watches) surfaces its own mistakes — so keep the guides to what the model can't infer or discover fast: the project sketch, the capture recipe, and the few silent-failure traps that pass a compile but break at runtime.
- When you change or remove a feature, describe the new state on its own terms. Name the new thing as if it were always the design.
