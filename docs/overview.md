# TAO-NOT-42 Overview

TAO-NOT-42 is organized as a staged embodied agent training project.

The Godot project in `stelle-env/` provides the 3D environment and environment-side systems. The Python package in `src/tao_not_42/` provides the learning-side bridge, wrappers, models, training, evaluation, and experiment utilities.

The current repository is still an inspectable skeleton: gameplay systems, model code, training loops, and transport are not implemented yet. The architecture direction is now documented so later code can be added incrementally without blurring the Godot/Python boundary.

Current design references:

- `docs/architecture.md`: project-level ownership notes.
- `docs/architecture/offline_training_dataflow.md`: offline Godot-to-Python dataset-batch training flow.
- `docs/architecture/model_structure_v1_1.md`: first-stage visual perception model design baseline.
- `docs/architecture/model_usage_calculation.md`: concrete calculation profile for input sizes, feature maps, sampling ratios, and parameter budget.
- `docs/assets/kaykit_assets.md`: extracted KayKit character/platformer asset guide for future Godot scene design.
- `docs/references/model_literature.md`: researched literature and implementation references for the model design.
