# TAO-NOT-42 Agent Instructions

TAO-NOT-42 is a staged end-to-end embodied agent training project. Keep the project inspectable and incremental.

## Project Boundaries

- `stelle-env/` is the Godot 4 environment. It owns scenes, environment-side state, observations, action execution, recording, and debug visualization.
- `src/tao_not_42/` is the Python learning package. It owns the bridge, wrappers, models, training, evaluation, data utilities, and experiment utilities.
- Do not put learning code in Godot. Do not put scene/gameplay implementation in Python.

## Working Rules

- Read this file and `PLAN.md` before editing.
- Prefer small, snake_case files and folders.
- Add stubs before broad systems. A stub should name the responsibility and expose a narrow future extension point.
- Do not copy large external templates.
- Do not add heavy dependencies unless a milestone explicitly calls for them.
- Prefer factory-style construction and composition over Python class inheritance.
- Prefer simple implementations over complex frameworks.
- Keep Python compatible with Python 3.10+.
- Target Godot 4.6 for environment work.
- Preserve support for C# code in the Godot project when adding environment-side systems.
- Keep neural network training, full gameplay, and protocol complexity out of the first skeleton.

## Project Documents

Always start with `PLAN.md` to understand the current milestone and what is intentionally not implemented yet.

Use these documents when the task touches their area:

- `docs/overview.md`: read for a quick project map, especially when orienting a new task or summarizing repository state.
- `docs/architecture.md`: read before changing ownership boundaries, bridge assumptions, Godot/Python responsibilities, or top-level architecture notes.
- `docs/architecture/offline_training_dataflow.md`: read before designing or editing Godot data generation, dataset batch manifests, Python dataset loading, RAM loading policy, or the offline Godot-to-Python training flow. This file defines the 20 GB generated data-batch design.
- `docs/architecture/model_structure_v1_1.md`: read before changing model inputs, Peripheral-Foveal structure, time-encoded single-frame input, ConvGRU state handling, SAFRM, output heads, loss masks, or inference/training rules.
- `docs/architecture/model_usage_calculation.md`: read before changing model dimensions, parameter counts, memory budgets, batch-size calculations, hidden-state budgets, or 20 GB data-batch estimates.
- `docs/assets/kaykit_assets.md`: read before using KayKit character, prop, or platformer assets in Godot scenes, generated environments, semantic class planning, or visual-data diversity design.
- `docs/assets/quaternius_modular_sci_fi_megakit.md`: read before using Quaternius sci-fi walls, floors, props, columns, decals, or the sci-fi arena prototype. This file explains the free Standard package, texture handling, visual style, and scene paths.
- `docs/references/model_literature.md`: read before discussing cited literature, replacing backbone/temporal modules, or justifying YOLOv8/FastSAM/SAM/FPN/PANet/ROIAlign/ConvGRU/Mamba/VMamba/RWKV choices.

## Validation

- For Python changes, run an import smoke test when possible.
- For Godot changes, keep scripts valid-looking for Godot 4 and avoid committing generated `.godot/` cache files.
- Use `Godot_v4.6.1-stable_mono_win64_console.exe` from `PATH` for Godot command-line checks.
- Use `Godot_v4.6.1-stable_mono_win64_console.exe --headless --editor --path stelle-env --quit` to verify the Godot project loads.
- Summaries should separate implemented skeleton work from intentionally deferred behavior.
