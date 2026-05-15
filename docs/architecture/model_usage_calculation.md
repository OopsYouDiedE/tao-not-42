# Model Usage and Parameter Calculation

This document gives a concrete, reproducible calculation profile for the v1.1 visual perception design. It is a budget reference, not implementation code.

The model is stateful: every forward call consumes one current frame per view. Temporal accumulation happens through recurrent hidden state, not through a multi-frame RGB input tensor.

## 1. Calculation Assumptions

Backbone variants are intentionally replaceable, so this calculation separates known public model sizes from TAO-NOT-42-specific added modules.

Calculation profile:

- Peripheral balanced input: `224x126`, padded to `224x128` for stride compatibility.
- Foveal balanced input: `224x224`.
- Compact comparison input: Peripheral `160x90`, padded to `160x96`; Foveal `128x128`.
- Per-step input channels: `5`.
- Channel order: `RGB,time_sin,time_cos`.
- Time encoding period: `256` frames.
- Forward-call input style: one current frame, no sequence dimension.
- Training unroll length for calculation: `8` steps as a trainer-side BPTT setting, not a model input shape.
- Temporal stride sampling: `frame_skip` in `1,2,3,4`, corresponding to `60,30,20,15 Hz` at 60 Hz base capture.
- Feature strides: `P3=8`, `P4=16`, `P5=32`.
- Example channels: `P3=64`, `P4=128`, `P5=256`.
- ConvGRU hidden channels equal input channels.
- SAFRM uses `P3` only.
- ROI metadata vector has 6 fields: `cx, cy, w, h, scale, fov_angle`.
- Extra heads use a simple calculation block: `3x3 conv C->C` then `1x1 conv C->out`, with `C=64`.
- Fine class calculation assumes `16` fine classes plus `1` local-depth output.

Known public model-size anchors:

- YOLOv8n-seg: `3.4M` parameters according to Ultralytics FastSAM comparison docs.
- FastSAM-s: `11.8M` parameters according to Ultralytics FastSAM comparison docs.

## 2. Stateful Input Pixel and Memory Budget

| Profile | Peripheral | Foveal | Pixels / step | Float32 input, B=1 | Float32 input, B=8 | If 8-step BPTT frames are materialized, B=8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Compact | 160x96 | 128x128 | 31,744 | 0.61 MiB | 4.84 MiB | 38.75 MiB |
| Balanced | 224x128 | 224x224 | 78,848 | 1.50 MiB | 12.03 MiB | 96.25 MiB |

Formula:

```text
bytes_per_step = B * 5 * (Peripheral_pixels + Foveal_pixels) * bytes_per_value
```

Dataset storage can be lower if frames are stored as `uint8`. The table reports normalized float tensors after loading. The 8-step BPTT column is included only for trainer memory planning; it does not mean the model input has a `T` dimension.

## 3. Concrete Network Parameters

Input parameters:

| Parameter | Peripheral | Foveal |
| --- | ---: | ---: |
| Raw render size | `224x126` | `224x224` |
| Network padded size | `224x128` | `224x224` |
| Channels | `5` | `5` |
| Batch tensor | `[B,5,128,224]` | `[B,5,224,224]` |

Time image adapter:

```text
Conv2d(5, 16, kernel=3, padding=1) + SiLU
Conv2d(16, 3, kernel=1)
```

Adapter parameter calculation:

| Layer | Formula | Parameters |
| --- | --- | ---: |
| `5 -> 16`, `3x3` | `3*3*5*16 + 16` | 736 |
| `16 -> 3`, `1x1` | `1*1*16*3 + 3` | 51 |
| Per branch | - | 787 |
| Peripheral + Foveal | - | 1,574 |

## 4. Feature Map Shapes

Balanced Peripheral `224x128`:

| Level | Stride | Shape | Channels | Scalars |
| --- | ---: | ---: | ---: | ---: |
| P3 | 8 | 28x16 | 64 | 28,672 |
| P4 | 16 | 14x8 | 128 | 14,336 |
| P5 | 32 | 7x4 | 256 | 7,168 |
| Total | - | - | - | 50,176 |

Balanced Foveal `224x224`:

| Level | Stride | Shape | Channels | Scalars |
| --- | ---: | ---: | ---: | ---: |
| P3 | 8 | 28x28 | 64 | 50,176 |
| P4 | 16 | 14x14 | 128 | 25,088 |
| P5 | 32 | 7x7 | 256 | 12,544 |
| Total | - | - | - | 87,808 |

Compact Peripheral `160x96` total feature scalars: `26,880`.

Compact Foveal `128x128` total feature scalars: `28,672`.

## 5. ConvGRU Parameter Count

ConvGRU parameter formula for one feature level:

```text
params = 3 * (k*k*(C_in + C_hidden)*C_hidden + C_hidden)
```

With `k=3` and `C_hidden=C_in`:

| Level | Channels | Parameters |
| --- | ---: | ---: |
| P3 | 64 | 221,376 |
| P4 | 128 | 885,120 |
| P5 | 256 | 3,539,712 |
| P3+P4+P5 | - | 4,646,208 |

The documented v1.1 network uses `P3` ConvGRU for stateful accumulation. `P4` and `P5` values are listed for future extension planning, not as part of the documented parameter total.

## 6. SAFRM Parameter Count

SAFRM calculation:

| Component | Formula | Parameters |
| --- | --- | ---: |
| ROI metadata MLP | `6->32->128` | 4,448 |
| Fusion 1x1 conv | `128->64` | 8,256 |
| Fusion 3x3 conv | `64->64` | 36,928 |
| Delta 1x1 conv | `64->64` | 4,160 |
| Gate 1x1 conv | `64->1` | 65 |
| Total | - | 53,857 |

The `128` in the MLP output is `gamma,beta` for `64` Foveal P3 channels.

## 7. Extra Head Parameter Count

Using the simple head block:

```text
head_params(out) = (3*3*64*64 + 64) + (64*out + out)
```

| Head | Output channels | Parameters |
| --- | ---: | ---: |
| tracking embedding | 32 | 39,008 |
| target velocity | 2 | 37,058 |
| distance + uncertainty | 2 | 37,058 |
| ego motion | 12 | 37,708 |
| vibration | 3 | 37,123 |
| frame reliability | 1 | 36,993 |
| visibility | 1 | 36,993 |
| refined mask | 1 | 36,993 |
| fine class + local depth | 17 | 38,033 |
| Active-head subtotal | - | 336,967 |
| Optional UI/text interface | 1 | 36,993 |
| All-head subtotal if UI/text is enabled | - | 373,960 |

The base segmentation and bbox/class heads are assumed to be part of the selected YOLOv8-seg / FastSAM-style backbone package. If they are reimplemented locally, recalculate them from the chosen head definitions.

## 8. Model Parameter Budget

| Configuration | Calculation | Parameters |
| --- | --- | ---: |
| Dual YOLOv8n-seg-like branches + time adapters + P3 ConvGRU + SAFRM + active extra heads | `2*3.4M + 1,574 + 221,376 + 53,857 + 336,967` | 7,413,774 |
| Dual YOLOv8n-seg-like branches + time adapters + P3/P4/P5 ConvGRU + SAFRM + active extra heads | `2*3.4M + 1,574 + 4,646,208 + 53,857 + 336,967` | 11,838,606 |
| FastSAM-s Peripheral + YOLOv8n-seg-like Foveal + time adapters + P3 ConvGRU + SAFRM + active extra heads | `11.8M + 3.4M + 1,574 + 221,376 + 53,857 + 336,967` | 15,813,774 |

These totals are practical planning numbers. Exact implementation totals must be recalculated from the actual PyTorch modules after the model files exist.

## 9. Sampling Ratio Calculation

For `10,000` ordinary mixed-state samples and no actively sampled teleport state:

| State | Ratio | Samples |
| --- | ---: | ---: |
| `stable_fixation` | 25% | 2,500 |
| `prompt_selection` | 20% | 2,000 |
| `micro_motion_parallax` | 20% | 2,000 |
| `occlusion_reacquisition` | 15% | 1,500 |
| `fast_rotation` | 10% | 1,000 |
| `strong_vibration` | 10% | 1,000 |

If there are no teleport frames in this ordinary pool:

- Target-related losses are active for `80%` of ordinary samples.
- Target-related losses are disabled for the `20%` fast-rotation / strong-vibration samples.
- Ego-motion, vibration, and reliability losses can remain active for those bad-frame states.

If teleport frames enter the batch with rate `p`, then continuous-motion loss availability should be reduced by that rate:

```text
target_velocity_active_ratio = ordinary_target_active_ratio - teleport_overlap_ratio
ego_motion_active_ratio = base_ego_motion_active_ratio - teleport_ratio
tracking_active_ratio = ordinary_tracking_active_ratio - teleport_overlap_ratio
```

The exact overlap depends on whether teleport samples are admitted as separate records or replace ordinary state samples.

Temporal stride sampling is independent from scene-state sampling for ordinary non-teleport records:

| `frame_skip` | Effective rate at 60 Hz | Initial ratio | Samples per 10,000 ordinary records |
| ---: | ---: | ---: | ---: |
| `1` | 60 Hz | 40% | 4,000 |
| `2` | 30 Hz | 25% | 2,500 |
| `3` | 20 Hz | 20% | 2,000 |
| `4` | 15 Hz | 15% | 1,500 |

Do not use stride sampling to bridge over boundary teleport frames.

## 10. Boundary Teleport Hidden-State Budget

For balanced Peripheral P3:

```text
hidden scalars = 28 * 16 * 64 = 28,672
hidden tensor shape = [B, 64, 16, 28]
FP32 memory = 114,688 bytes = 112 KiB per sample
FP16 memory = 57,344 bytes = 56 KiB per sample
```

For balanced P3+P4+P5:

```text
hidden scalars = 50,176
FP32 memory = 200,704 bytes = 196 KiB per sample
FP16 memory = 100,352 bytes = 98 KiB per sample
```

Teleport behavior should reset or decay this hidden state instead of treating pre- and post-teleport frames as continuous motion.

## 11. Offline 20 GB Data-Batch Budget

The environment-side training flow uses generated dataset batches:

```text
target_data_batch_size = 20 GB
```

Size conversion:

```text
20,000,000,000 bytes = 18.63 GiB
20 GiB = 21,474,836,480 bytes
```

Python's intended loader policy is full-batch RAM loading. A generated dataset batch is loaded completely, trained, and then released. This is different from a neural-network mini-batch.

For balanced normalized Float32 model inputs:

```text
per-step input ~= 1.50 MiB
20 GB / 1.50 MiB ~= 12,682 samples
```

For compact normalized Float32 model inputs:

```text
per-step input ~= 0.61 MiB
20 GB / 0.61 MiB ~= 31,502 samples
```

These sample counts are only tensor-size equivalents. Actual record count depends on whether Godot stores images as compressed files, `uint8` arrays, or already-normalized tensors, and on how much label/mask data is included.

Memory planning must include:

- raw loaded batch payload
- decoded image arrays
- generated time planes
- labels and masks
- normalized tensors
- model activations
- optimizer state
- temporary augmentation buffers

The manifest's `actual_size_bytes` and `record_count` are the authoritative values for each generated batch.
