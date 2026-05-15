# TAO-NOT-42

TAO-NOT-42 is an embodied visual perception training project built around a Godot 3D environment and a Python learning package.

The core idea is simple: Godot creates controlled visual experience, exports complete supervision, and Python trains from that data offline. This keeps the environment and learning code separate and makes each stage easier to inspect.

## Project Shape

- `stelle-env/`: Godot 4.6 environment. It owns scenes, camera motion, observations, labels, recording, and debug visualization.
- `src/tao_not_42/`: Python learning package. It will own data loading, models, training, evaluation, and experiment utilities.
- `docs/`: design documents for the dataflow, model structure, calculations, and references.

## Included Assets

The Godot project includes KayKit Adventurers and Platformer assets under `stelle-env/assets/vendor/kaykit/`. The packs are CC0. For Godot 4, this project keeps the glTF/GLB-oriented asset set and removes FBX/OBJ source variants from the extracted folders.

It also includes the free Standard version of Quaternius Modular Sci-Fi MegaKit under `stelle-env/assets/vendor/quaternius/`. This pack is CC0 and is useful for the gray-blue, low-poly sci-fi arena direction shown in the reference image. The project keeps the glTF runtime files and required texture PNGs, not the FBX/OBJ variants.

The current main scene is `stelle-env/scenes/main.tscn`. It uses `stelle-env/scripts/procedural_room_generator.gd` to assemble a `20x20` generated arena from Platformer glTF models, with a clear ring path for future CameraRig looping.

To capture a runtime preview, run `stelle-env/scenes/preview_capture.tscn`. It saves a viewport screenshot to `stelle-env/screenshots/procedural_room_preview.png`.

A second prototype scene, `stelle-env/scenes/scifi_arena.tscn`, assembles a `20x20` sci-fi training arena with procedural gray-blue wall blocks, multi-level platforms, ramps, traps, humanoid targets, drones, cyan loop markers, purple teleport gates, and a debug-style overlay. It uses simple generated geometry plus nearby KayKit replacement props where the exact reference models are not present. Its preview capture scene is `stelle-env/scenes/scifi_preview_capture.tscn`, which saves `stelle-env/screenshots/scifi_arena_preview.png`.

## Training Design

The first training path is offline supervised training, not online RL.

Godot generates a dataset batch, Python loads the whole batch into memory, trains on it, discards it, then moves to the next batch. The planned generated batch size is `20 GB` each time. This is a dataset batch, not a neural-network mini-batch.

## Training Goals

The first-stage goal is to train a visual perception model that can stay useful while the camera platform moves around the Godot arena.

The model should learn to:

- select and segment a prompted target
- track the target through short-term motion and occlusion
- estimate target distance and motion
- estimate CameraRig ego-motion
- classify vibration and frame reliability
- use Peripheral wide-view context with Foveal high-resolution refinement

Stable frames should update target state, mask, bbox, distance, and velocity. Bad frames, strong vibration, fast rotation, and boundary teleport events should preserve or reset state safely instead of teaching the model false continuous motion.

## Model Design

The first-stage model is a multi-head visual perception model for the Godot environment.

It receives one frame per step, not a stack of RGB frames. Each frame is time-encoded as:

```text
RGB + time_sin + time_cos
```

History is handled inside the model with recurrent state, mainly a ConvGRU over Peripheral features. Training can randomize the time gap between recurrent updates: frame skips `1,2,3,4` correspond to `60,30,20,15 Hz` on a 60 Hz base timeline.

The visual structure is:

- Peripheral branch: wide view, global context, target discovery, motion, reliability, vibration, and ego-motion.
- Foveal branch: narrow high-resolution view for local refinement.
- SAFRM: aligns Foveal features with the Peripheral ROI before fusion and gated write-back.

Godot controls the training loss masks. Bad frames, strong vibration, fast rotation, and boundary teleport events are labeled so Python does not train the wrong losses.

## Current Status

This repository is still a skeleton. It now has a starter Godot main scene that procedurally assembles a simple room from KayKit Platformer assets, but full gameplay systems, data recorders, dataset loaders, model code, and training loops are not implemented yet.

Start with:

- `PLAN.md`
- `AGENTS.md`
- `docs/architecture.md`
