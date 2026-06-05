# Interactive Protocol

How to collaborate with the user instead of running the whole build unattended. Checkpoint at the decisions that depend on their taste or intent; build freely between them. The user is watching the live URL, so they are your fastest verifier — let them judge motion and feel rather than over-specifying probes for yourself.

## Resume

If `PLAN.md` exists, read it (plus `STRUCTURE.md`, `MEMORY.md`, `ASSETS.md`), summarize where the work stands, and confirm what to continue before editing.

## Reference image

A reference is optional. Skip it when the look is obvious from the brief or the scene is trivial, and say briefly why. Otherwise propose one specific, information-dense scene (the gameplay moment that best fixes layout, scale, and camera), confirm the idea, then generate it with the CLI in `visual-target.md`.

Show it to the user in the browser at `http://127.0.0.1:5173/reference.png` (the dev server serves project-root `reference*.png`). Then ask how to use it, and record the answer in `PLAN.md`:

- **precise** — treat `reference.png` as a match target; reference consistency is a verification criterion.
- **art-direction** — palette, mood, and material language only; layout and composition are free.
- **rough guide** — loose inspiration; no reference-match gate.

This mode controls how strict downstream verification is — don't hold a rough-guide build to a precise-match bar.

## Build approach

Propose a strategy shaped by the light read (`decomposer.md` Pass 1), recommend one, and let the user pick. Don't impose — the optimal choice depends on the task:

- **one-shot-then-polish** — build a first cut of the whole game fast in `main`, then polish from the user's live reactions. Good when the shape is clear and most risk is in feel, not feasibility.
- **hard-parts-first** — land the uncertain parts first (in `main`, watched live), prove them, then assemble the routine systems around them. Good when feasibility is the main risk.
- **linear** — one feature after another, each verified live before the next. Good for incremental or open-ended briefs.

Other shapes are fine; these are starting points. Whatever the user picks, write the thin PLAN.md in that shape (`decomposer.md` Pass 2).

## Assets

Assets are part of the build, not a gate before it — and *when* to generate them is a judgment call, not a default. Match the timing to where the work is:

- **Placeholders first** when the substance is logic and feel — primitives, flat colors, procedural stand-ins let you get the mechanics right on the live URL, then generate the real assets once the design that needs them is settled (how many, what sizes, what survived). You generate against known dimensions instead of guesses, and don't pay for assets the design discards.
- **Real assets first** when the substance *is* the assets — an art-carried game, or a precise reference to match, where a primitive stand-in tells you nothing and the look is the thing being judged. Generate the key assets early and build around them.

Most tasks sit between; read which way the weight falls and choose. When a budget is provided, assets cost real money: confirm the list and rough cost (`asset-planner.md`) before spending, wherever that spend falls.

## Live delivery

The running dev server is the deliverable.

- Start `npm run dev` early and keep it alive; surface the URL the moment something is showable.
- Build in `?scene=main`; tell the user to refresh the browser when you want them to see a change.
- Isolate a feature into its own `?scene=<name>` route only on demand — when the main scene is too busy to judge the feature, or the user asks to see it alone. Add the route in `src/game/scenes/registry.ts` and send the user `http://127.0.0.1:5173/?scene=<name>`. Fold it back into `main` once accepted.
- Checkpoint at slice boundaries: show the state, take the user's steer, revise `PLAN.md`. Let them redirect at any time.

## Shareable URL (remote agent)

When the user can't reach `127.0.0.1` (you're running on a different machine):

- LAN: `npm run dev:lan` (`vite --host 0.0.0.0`) and give the user the machine's LAN URL.
- Public: a tunnel such as `cloudflared tunnel --url http://127.0.0.1:5173` for a temporary HTTPS link.

Paste the resulting link instead of `127.0.0.1`. Scene routes (`?scene=<name>`) and `/reference.png` work the same through it.
