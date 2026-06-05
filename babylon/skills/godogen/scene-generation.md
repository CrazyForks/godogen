# Scene Generation

`src/game/scenes/main.ts` is the main game implementation entry. Each scene module under `src/game/scenes/` must export:

```ts
export async function createScene(app: BabylonApp): Promise<Scene>
```

`createScene` should create a fresh `Scene` every time. It runs on each page load and whenever the `?scene=` route changes.

## Scene Router

`src/main.ts` selects the active scene from the `?scene=<name>` URL param and resolves it through `src/game/scenes/registry.ts`. `main` is the default and the primary surface — build the game there. Add a route only when you isolate a scene on demand (the main scene is too busy to judge a feature, or the user asks): create `src/game/scenes/<name>.ts` exporting `createScene`, add a line to `SCENE_MODULES`, and share `http://127.0.0.1:5173/?scene=<name>`. Shared gameplay objects live under `src/game/` and are imported by whichever scenes need them. Fold an accepted isolated scene back into `main`.

## Ownership Pattern

Small games can keep scene setup and a few classes in `src/game/scenes/main.ts`. Move code out when ownership becomes clearer:

```text
src/game/world/GameWorld.ts
src/game/actors/Player.ts
src/game/actors/Enemy.ts
src/game/camera/CameraController.ts
src/game/ui/UIController.ts
```

Gameplay objects may own Babylon meshes, materials, animations, input state, and cleanup. Keep object-specific behavior with the object. Keep broad world rules in `GameWorld` or equivalent.

## Update Loop

Prefer one high-level scene update hook that delegates to owned objects:

```ts
scene.onBeforeRenderObservable.add(() => {
  const delta = scene.getEngine().getDeltaTime() / 1000;
  world.update(delta);
});
```

Dispose scene-owned observers, meshes, materials, textures, and sounds through Babylon scene disposal whenever possible. If a gameplay object attaches DOM/window listeners, give it an explicit `dispose()`.

## Camera

Use Babylon cameras directly. `ArcRotateCamera` is a good default for inspection and generated scenes; use `UniversalCamera` or custom camera controllers for first-person or character-driven games.

Attach controls to `app.canvas` only for interactive camera modes. Isolated review scenes should use deterministic, scripted camera motion rather than live pointer input, so the feature is judgeable without manual control.

## Input

Use `InputState` or a game-specific `InputManager` to expose semantic actions. Do not spread raw key checks through unrelated classes.

## UI

Use DOM HUD (`#hud`) for text overlays, menus, and conventional browser UI. Use Babylon GUI or mesh text only when UI must live in the 3D world.

## Asset Loading

Keep asset URL imports in `src/game/assets.ts`:

```ts
import heroUrl from "../assets/models/hero.glb?url";

export const assets = {
  hero: heroUrl
} as const;
```

Load GLB/GLTF assets with `@babylonjs/loaders/glTF` imported once in the module that loads them.

## Isolated Review Scenes

When you isolate a feature into its own `?scene=<name>` route for live review, make it easy to judge on its own:

- a fixed or scripted camera that frames the feature
- a seeded or autoplaying setup so the behavior is visible without manual input
- the transition or motion the feature is about, looping or repeatable

Keep the isolated scene focused on the one thing under review, then fold the proven code back into `main`.
