# Architecture Notes

## Godot Environment

`stelle-env/` owns the simulated world. Future systems should stay small and focused: episode control, task state, observation construction, action execution, object registration, recording, and debug viewing. The project targets Godot 4.6 and should preserve C# support.

## Python Learning Package

`src/tao_not_42/` owns the learning side. Future modules should cover the Godot bridge, environment wrappers, models, training, data handling, evaluation, and shared utilities only when those milestones need them. Python code should stay compatible with Python 3.10+ and prefer simple factory/composition patterns over inheritance-heavy designs.

## Boundary

The bridge should eventually be the only normal communication path between the Godot environment and Python learning code. Until the protocol is drafted, both sides should stay as simple stubs.

## Offline Training Dataflow

The first-stage training design is offline supervised training, documented in `docs/architecture/offline_training_dataflow.md`.

Godot generates persisted dataset batches with images, time encoding metadata, target labels, ego-motion labels, scene states, and loss masks. Python then loads a complete generated dataset batch into RAM, trains on it, releases it, and moves to the next generated batch.

The planned dataset batch target is `20 GB` per generated batch. This is a dataset-batch size, not a neural-network mini-batch size. Python should fail fast if a complete generated batch cannot fit in memory; silent streaming fallback would change the intended training design.

## First-Stage Model Design

The current model design baseline is documented in `docs/architecture/model_structure_v1_1.md`. It defines a unified multi-state visual perception model for the Godot 3D environment, with:

- Stateful single-frame Peripheral-Foveal dual-view input.
- Time-encoded image planes on each input frame.
- YOLOv8-seg / FastSAM-style prompt-guided candidate selection.
- ConvGRU stateful fusion on spatial feature maps.
- SAFRM spatially aligned foveal refinement.
- Godot-driven supervision masks for target, motion, reliability, vibration, and boundary teleport states.

This document is architectural only. It does not add learning code to Godot and does not add gameplay implementation to Python.
