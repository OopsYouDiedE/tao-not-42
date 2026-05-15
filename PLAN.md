# TAO-NOT-42 Plan

## Current Milestone: Lean Skeleton

Create the smallest useful project skeleton with clear ownership boundaries. Future systems are listed here first, then added as small files only when a milestone needs them.

## Completed In This Milestone

- Root coordination files: `AGENTS.md` and `PLAN.md`.
- Basic project docs under `docs/`.
- First-stage visual perception model design baseline under `docs/architecture/model_structure_v1_1.md`.
- Offline Godot-to-Python training dataflow under `docs/architecture/offline_training_dataflow.md`.
- Model usage and parameter calculation reference under `docs/architecture/model_usage_calculation.md`.
- Literature/reference notes under `docs/references/model_literature.md`.
- KayKit vendor assets extracted under `stelle-env/assets/vendor/kaykit/`, with glTF/GLB runtime formats retained.
- Quaternius Modular Sci-Fi MegaKit Standard assets extracted under `stelle-env/assets/vendor/quaternius/`, with glTF runtime files and texture PNGs retained.
- Starter procedural room scene under `stelle-env/scenes/main.tscn`.
- Procedural Platformer room generator under `stelle-env/scripts/procedural_room_generator.gd`.
- Starter sci-fi arena scene under `stelle-env/scenes/scifi_arena.tscn`.
- Procedural sci-fi arena generator under `stelle-env/scripts/scifi_arena_generator.gd`.
- Minimal Python package entrypoint under `src/tao_not_42/`.
- Existing Godot 4.6 project under `stelle-env/`.

## Next Milestones

1. Define smoke command rules.
   - Document Python import/package checks.
   - Document Godot 4.6 Mono command-line checks.
   - Keep smoke checks fast and non-comprehensive.

2. Define the bridge protocol draft.
   - Decide the minimal offline dataset-batch manifest and handoff shape.
   - Document observation and action dictionaries before adding bridge code.
   - Keep transport local and simple until the first data-generation smoke loop works.

3. Add the first Python-side module only when needed.
   - Start with a factory-style bridge or wrapper module.
   - Avoid inheritance-heavy designs.
   - Keep Python compatible with 3.10+.

4. Add the first Godot-side system only when needed.
   - Candidate next systems: episode manager, task manager, observation builder, action executor, object registry, recorder, debug viewer.
   - Extend the starter procedural room incrementally and preserve C# support.

5. Add learning components later.
   - Use `docs/architecture/model_structure_v1_1.md` as the design baseline.
   - Add model and training dependencies only when the environment wrapper has a stable contract.

## Not Yet Implemented

- No full gameplay environment.
- No neural network models.
- No training loop.
- No offline dataset-batch loader.
- No real Godot/Python transport.
- No Python wrapper modules beyond the package entrypoint.
- No Godot recorder, observation, action, task, or episode systems yet.
