import "./style.css";
import { BabylonApp, type SceneFactory } from "./app/BabylonApp";
import { resolveSceneModule } from "./game/scenes/registry";

// Bundled lazy loaders for every scene module — keys look like
// "./game/scenes/main.ts". The active scene is chosen from the ?scene= URL
// param. There is no auto hot reload: refresh the browser to apply edits, so
// game state survives until you choose to reset it.
const sceneLoaders = import.meta.glob<{ createScene: SceneFactory }>(
  "./game/scenes/*.ts"
);

const canvas = document.querySelector<HTMLCanvasElement>("#game-canvas");

if (!canvas) {
  throw new Error("Missing #game-canvas");
}

const app = new BabylonApp(canvas);

const moduleKey = resolveSceneModule(
  new URLSearchParams(location.search).get("scene")
).replace("/src/", "./");

const loadScene = sceneLoaders[moduleKey];

if (!loadScene) {
  throw new Error(`No scene module registered for "${moduleKey}"`);
}

const mod = await loadScene();
await app.load(mod.createScene);
app.start();
