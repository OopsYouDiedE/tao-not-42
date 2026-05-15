# Model Literature and Reference Notes

This reference collects the main papers and official implementation references behind the v1.1 model design. Notes are written as design takeaways for TAO-NOT-42, not as full paper reviews.

## Detection, Segmentation, and Prompt Selection

### YOLOv8 / YOLOv8-seg

Reference: [Ultralytics YOLOv8 docs](https://docs.ultralytics.com/models/yolov8)

Key points:

- YOLOv8 is an implementation/software reference rather than a formal research paper.
- It supports detection, instance segmentation, pose, oriented boxes, and classification in one model family.
- The docs describe an anchor-free split head and updated backbone/neck design.
- For TAO-NOT-42, YOLOv8-seg is a practical backbone family because it provides multi-scale features plus detection/segmentation heads that can be extended with tracking, motion, distance, reliability, and vibration heads.

Design implication:

- Cite Ultralytics software/docs for YOLOv8 usage.
- Avoid making the TAO-NOT-42 architecture depend on Ultralytics internals that may change across package versions.

### Segment Anything

Reference: [Segment Anything, Kirillov et al., 2023](https://arxiv.org/abs/2304.02643)

Key points:

- SAM formalized promptable segmentation and showed strong zero-shot transfer with point, box, and mask-like prompts.
- Its strength is prompt-conditioned mask generation, but the full model is large for a tight Godot training loop.
- TAO-NOT-42 borrows the promptable segmentation idea, not the requirement to use SAM as the actual model.

Design implication:

- Prompt support should be explicit, but prompt handling must not replace temporal fusion or Godot-driven supervision.

### Fast Segment Anything / FastSAM

References:

- [Fast Segment Anything, Zhao et al., 2023](https://arxiv.org/abs/2306.12156)
- [Ultralytics FastSAM docs](https://docs.ultralytics.com/models/fast-sam)

Key points:

- FastSAM reframes promptable segmentation into two stages: all-instance segmentation followed by prompt-guided selection.
- The paper reports a CNN detector with an instance-segmentation branch as a faster alternative to heavy Transformer-based SAM-style inference.
- Ultralytics documents FastSAM as based on YOLOv8-seg and lists FastSAM-s at `11.8M` parameters and YOLOv8n-seg at `3.4M` parameters.

Design implication:

- The first-stage TAO-NOT-42 prompt path should generate candidates first and select by prompt second.
- This keeps the target-selection interface simple while leaving room for a later prompt encoder.

## Multi-Scale Feature Fusion

### Feature Pyramid Networks

Reference: [Feature Pyramid Networks for Object Detection, Lin et al., 2016/2017](https://arxiv.org/abs/1612.03144)

Key points:

- FPN uses a top-down path with lateral connections to combine high-level semantic features with higher-resolution feature maps.
- It is a generic feature extractor for multi-scale detection.

Design implication:

- TAO-NOT-42 should expose `P3`, `P4`, and `P5` feature levels rather than designing heads around a single feature map.

### Path Aggregation Network

Reference: [Path Aggregation Network for Instance Segmentation, Liu et al., 2018](https://arxiv.org/abs/1803.01534)

Key points:

- PANet adds bottom-up path augmentation and adaptive pooling to improve information flow across feature levels.
- It is especially relevant to instance segmentation and mask quality.

Design implication:

- A YOLOv8-style PAN/FPN neck is compatible with the multi-head design, but TAO-NOT-42 should keep the feature-pyramid interface abstract.

### Mask R-CNN and ROIAlign

Reference: [Mask R-CNN, He et al., 2017](https://arxiv.org/abs/1703.06870)

Key points:

- Mask R-CNN added a parallel mask branch to Faster R-CNN and introduced ROIAlign to avoid misalignment from coarse quantization.
- ROIAlign is a key reference for extracting fixed-size features from a continuous image-space region.

Design implication:

- SAFRM should use ROIAlign-style extraction from Peripheral features before fusion with Foveal features.
- Direct feature concatenation is invalid unless both feature maps represent the same spatial coordinate frame.

## Temporal and Active Vision

### ConvGRU for Spatial-Temporal Features

Reference: [Delving Deeper into Convolutional Networks for Learning Video Representations, Ballas et al., 2015/2016](https://arxiv.org/abs/1511.06432)

Key points:

- The paper uses GRU-style recurrence over convolutional feature maps and replaces dense GRU transitions with convolutional operations.
- This preserves spatial structure and controls parameter growth compared with flattening feature maps into dense recurrent states.

Design implication:

- ConvGRU is a good first-stage temporal module for a single-frame visual stream because it keeps the 2D layout needed for masks, motion, and ROI refinement while carrying history in hidden state.

### Recurrent Models of Visual Attention

Reference: [Recurrent Models of Visual Attention, Mnih et al., NeurIPS 2014](https://papers.nips.cc/paper/5542-recurrent-models-of-visual-attention)

Key points:

- The model processes selected high-resolution regions rather than the entire large image at full resolution.
- It motivates active glimpses, recurrent state, and a compute budget that is not purely tied to full-frame pixel count.

Design implication:

- TAO-NOT-42's Peripheral-Foveal split follows the same broad efficiency principle, but uses Godot geometry and supervised ROI metadata instead of a pure RL glimpse policy.

### Foveation in the Era of Deep Learning

Reference: [Foveation in the Era of Deep Learning, Killick et al., 2023](https://arxiv.org/abs/2312.01450)

Key points:

- The paper studies active foveated vision and compares choices such as foveation degree and number of fixations.
- It supports the idea that foveated processing can improve efficiency under pixel or compute budgets.

Design implication:

- Foveal refinement should remain local and budgeted; Peripheral remains responsible for global context and ROI proposal.

## Later Temporal Backbone Candidates

### Mamba

Reference: [Mamba: Linear-Time Sequence Modeling with Selective State Spaces, Gu and Dao, 2023](https://arxiv.org/abs/2312.00752)

Key points:

- Mamba introduces selective state-space sequence modeling with linear sequence scaling and hardware-aware recurrent computation.
- It is strongest as a general sequence backbone and is especially attractive for long sequences.

Design implication:

- Mamba is a later candidate if the project needs longer context than ConvGRU can comfortably handle.

### VMamba

Reference: [VMamba: Visual State Space Model, Liu et al., 2024](https://arxiv.org/abs/2401.10166)

Key points:

- VMamba adapts Mamba-style state-space modeling to vision using 2D selective scan.
- It targets global receptive fields with linear complexity for visual perception tasks.

Design implication:

- VMamba is a plausible future replacement for the temporal/spatial backbone, but it is not the first-stage default because the current task uses explicit spatial maps and a stateful per-frame update interface.

### RWKV

Reference: [RWKV: Reinventing RNNs for the Transformer Era, Peng et al., 2023](https://arxiv.org/abs/2305.13048)

Key points:

- RWKV combines Transformer-like parallel training with RNN-like inference and constant inference memory in language-oriented sequence modeling.
- Its main evidence base is not the same as short-horizon spatial feature fusion for detection/segmentation.

Design implication:

- RWKV should not be the first-stage temporal module for TAO-NOT-42's visual perception model.

## Licensing and Practical Notes

- YOLOv8 and Ultralytics models have licensing constraints documented by Ultralytics. Check the active license before using pretrained weights or code in a distributable project.
- The first implementation should keep backbone construction behind a factory-style interface so YOLOv8-seg, FastSAM-like, or a local lightweight segmentation backbone can be swapped without changing Godot labels or loss-mask policy.
- The documentation here describes architecture and references only; it does not require adding heavy dependencies to the current skeleton.
