// Scene routes addressable by URL: http://127.0.0.1:5173/?scene=<name>
//
// `main` is the default and the primary surface — build the game here. Add an
// entry only when you isolate a scene on demand (the main scene is too noisy to
// judge a feature, or the user asks to see it on its own). Each module exports
// `createScene(app): Promise<Scene>`.

export const SCENE_MODULES: Record<string, string> = {
  main: "/src/game/scenes/main.ts"
  // on-demand isolation only, e.g.
  // pathfinding: "/src/game/scenes/pathfinding.ts"
};

export const DEFAULT_SCENE = "main";

export function resolveSceneModule(name: string | null): string {
  return name && name in SCENE_MODULES
    ? SCENE_MODULES[name]
    : SCENE_MODULES[DEFAULT_SCENE];
}
