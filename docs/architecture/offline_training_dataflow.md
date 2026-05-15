# Offline Training Dataflow

This document defines the environment-side training-data design for TAO-NOT-42. The first-stage training flow is offline: Godot generates supervised data batches, and Python trains from those batches without driving Godot step-by-step during optimization.

## 1. Training Mode

The first-stage visual perception model uses offline supervised training.

```text
Godot data generation
    -> persisted dataset batch
    -> Python full-batch load into RAM
    -> training over that loaded batch
    -> discard loaded batch
    -> request or consume next generated batch
```

This is not online reinforcement learning. Python does not update the model while Godot is synchronously stepping the environment. Godot's job is to generate diverse observations and complete supervision. Python's job is to load a generated data batch and train quickly.

## 2. Dataset Batch Size

The planned generated data batch size is:

```text
target_data_batch_size = 20 GB
```

Use `20 GB` as the nominal generator target. For exact manifests, record bytes explicitly:

```text
20,000,000,000 bytes = 18.63 GiB
20 GiB = 21,474,836,480 bytes
```

The manifest must state whether the batch target was decimal `GB` or binary `GiB`.

## 3. Ownership Boundary

Godot owns:

- scene randomization and scenario scheduling
- CameraRig / HeadPivot movement
- boundary teleport event generation and labeling
- Peripheral and Foveal image capture
- time encoding fields needed to build time-encoded images
- target masks, boxes, IDs, depth, velocity, and visibility labels
- ego-motion, vibration, reliability, and loss-mask labels
- dataset batch writing and manifest generation

Python owns:

- full data-batch loading
- data validation against the manifest
- tensor construction
- model training
- metric reporting
- releasing the loaded data batch from memory after training

Do not put learning code in Godot. Do not put scene/gameplay generation logic in Python.

## 4. Data Batch Contents

Each record represents one model step, not a multi-frame RGB sequence:

```text
record_t = {
  peripheral_frame,
  foveal_frame,
  time_encoding,
  camera_and_gaze_metadata,
  target_ground_truth,
  ego_motion_ground_truth,
  scene_state,
  loss_masks
}
```

The image payload can be stored compactly on disk, but the Python loader builds the model input as:

```text
peripheral_time_image_t: [5, H_peri, W_peri]
foveal_time_image_t:     [5, H_fov, W_fov]
```

with channels:

```text
R, G, B, time_sin, time_cos
```

The batch should include enough metadata to reconstruct the exact time planes without guessing:

- `frame_index`
- `previous_frame_index`
- `frame_skip`
- `episode_id`
- `episode_time_seconds`
- `delta_time_seconds`
- `time_period_frames`

For a 60 Hz base timeline, first-stage training should support randomized temporal stride:

```text
frame_skip = 1 -> 60 Hz
frame_skip = 2 -> 30 Hz
frame_skip = 3 -> 20 Hz
frame_skip = 4 -> 15 Hz
```

This should be represented as metadata on single-frame records. It is not a multi-frame RGB input.

## 5. Manifest Requirements

Every generated data batch must include a manifest. The manifest should be small enough to read before loading the full payload.

Required manifest fields:

```text
batch_id
generator_version
godot_version
created_at
target_size_bytes
actual_size_bytes
record_count
schema_version
image_storage_format
peripheral_size
foveal_size
time_period_frames
base_capture_hz
frame_skip_values
frame_skip_counts
scene_state_counts
boundary_teleport_count
loss_mask_active_counts
shards
checksum
```

`shards` may be one file or multiple files. The training policy is still full-batch RAM loading: all shards for a dataset batch are loaded before training that batch.

## 6. Python Loading Policy

Python should load the entire generated data batch into memory before training that batch.

Policy:

- Read and validate the manifest first.
- Check that available RAM can hold the loaded batch and training tensors.
- Load all records for the current dataset batch.
- Train on the loaded in-memory records.
- Release references to the loaded records after training.
- Do not mix old discarded data into the next batch unless a later design explicitly adds replay.

If memory is insufficient, fail fast with a clear message rather than silently falling back to streaming. The intended design is full-batch RAM loading.

## 7. Memory Consequences

A nominal `20 GB` payload is `18.63 GiB` before Python object overhead, decoded images, normalized float tensors, labels, model activations, optimizer state, and temporary augmentation buffers.

For the balanced input profile, one stateful model step as normalized Float32 input is approximately:

```text
1.50 MiB per sample at B=1-equivalent tensor size
```

This means `20 GB` of already-normalized balanced Float32 input would correspond to roughly:

```text
12,682 samples
```

Actual record count will differ if the stored batch uses compressed or `uint8` images. The manifest's `record_count` and `actual_size_bytes` are therefore the source of truth.

## 8. Diversity Policy

To increase diversity across 20 GB batches, Godot should vary:

- scene layout
- object classes and poses
- object visibility and occlusion
- CameraRig phase in the forward-loop path
- HeadPivot local rotations
- local translations and bobbing
- vibration state
- fast-rotation events
- prompt type and prompt payload
- lighting and material variants when available
- temporal stride, using `frame_skip` values `1,2,3,4`

`boundary_teleport_event` remains a special system event. It should be recorded and masked correctly, not treated as ordinary continuous motion.

## 9. Deferred Behavior

The current skeleton only documents this offline dataflow. It does not yet implement:

- Godot recorders
- dataset batch files
- Python dataset loaders
- RAM budget checks
- training loops
- model code

Those systems should be added incrementally when their milestone starts.
