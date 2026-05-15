# KayKit Asset Packs

This document explains the two KayKit packs extracted into the Godot project for future character, level, and training-scene design.

## Location

Both packs are stored under:

```text
stelle-env/assets/vendor/kaykit/
```

Extracted folders:

```text
stelle-env/assets/vendor/kaykit/KayKit_Adventurers_2.0_FREE/
stelle-env/assets/vendor/kaykit/KayKit_Platformer_Pack_1.0_FREE/
```

Keep these folders as vendor assets. Do not edit original files directly when building scenes; create project-side scenes, prefabs, or wrappers that reference them.

## License

Both packs include `License.txt` files and are licensed as Creative Commons Zero (`CC0`).

Credit is optional, but recommended:

```text
Kay Lousberg, www.kaylousberg.com
```

## Import Format Guidance

For Godot 4, prefer:

- `.glb` character files when available.
- `.gltf` level/prop files when available.

FBX, OBJ, and OBJ material (`.mtl`) variants were removed from the extracted Godot asset folders. The project keeps the glTF/GLB-oriented runtime set.

## Adventurers Character Pack

Path:

```text
stelle-env/assets/vendor/kaykit/KayKit_Adventurers_2.0_FREE/
```

Summary:

- Extracted size: about `22 MB`.
- File count after extraction: `294`.
- Main folders: `Characters`, `Animations`, `Assets`, `Samples`, `Textures`.

### Characters

Recommended Godot character files:

```text
Characters/gltf/Barbarian.glb
Characters/gltf/Knight.glb
Characters/gltf/Mage.glb
Characters/gltf/Ranger.glb
Characters/gltf/Rogue.glb
Characters/gltf/Rogue_Hooded.glb
```

The basic role set is:

- Barbarian
- Knight
- Mage
- Ranger
- Rogue

`Rogue_Hooded` is an extra Rogue variant.

### Character Textures

Texture files are present beside the character models and also under `Textures/`:

```text
barbarian_texture.png
knight_texture.png
mage_texture.png
ranger_texture.png
rogue_texture.png
```

### Animations

Recommended animation files:

```text
Animations/gltf/Rig_Medium/Rig_Medium_General.glb
Animations/gltf/Rig_Medium/Rig_Medium_MovementBasic.glb
```

These are rig-level animation libraries for the medium rig. When building playable or observed agents, check animation compatibility with the selected character import before depending on a clip name.

### Props and Equipment

The `Assets/gltf/` folder contains equipment and interaction props:

- arrows and bundles
- bows and crossbows
- one-handed and two-handed axes
- dagger
- shields
- smoke bomb
- spellbooks
- staff
- swords
- wand
- mugs
- quiver

Use these for target classes, carried objects, pickups, prompt-selection objects, and occlusion/interaction variety.

### Samples

`Samples/` contains preview images for quick visual reference. They are useful for documentation and manual asset selection, not for runtime scene construction.

## Platformer Pack

Path:

```text
stelle-env/assets/vendor/kaykit/KayKit_Platformer_Pack_1.0_FREE/
```

Summary:

- Extracted size: about `41 MB`.
- File count after extraction: `2312`.
- Main folders: `Assets`, `Samples`, `Textures`.

### Color Sets

Recommended Godot files are under:

```text
Assets/gltf/
```

Available color/material folders:

- `blue`: 83 glTF assets
- `green`: 83 glTF assets
- `red`: 83 glTF assets
- `yellow`: 83 glTF assets
- `neutral`: 38 glTF assets

Use colored sets to create visual diversity across generated data batches. Use `neutral` for wood/sign/structural pieces and less color-coded geometry.

### Level-Building Pieces

Common asset families include:

- `platform_*`: floors, blocks, holes, arrows, decorative blocks, slopes
- `barrier_*`: wall/blocking pieces in several sizes
- `railing_*`: corner and straight railings
- `pipe_*`: straight, 90-degree, 180-degree, and end pieces
- `arch_*`: arches for passages and landmarks
- `bracing_*`, `strut_*`, `structure_*`: support and structural detail
- `floor_wood_*`, `platform_wood_*`: neutral floor and platform pieces

These are the primary pieces for building obstacle courses, arenas, corridors, and controlled visual scenes.

### Interactive and Landmark Props

The pack also contains recognizable props:

- buttons
- levers
- flags
- hearts
- diamonds
- stars
- power icons
- springs
- bombs
- hoops
- signs and directional signage

Use these as prompt targets, landmarks, reward markers, distractors, or semantic classes for perception labels.

## Suggested TAO-NOT-42 Usage

For early Godot scenes:

- Use Platformer pieces to build simple looped arenas, corridors, occluders, and boundary zones.
- Use Adventurer characters as visible moving targets or prompt-selected tracked objects.
- Use props and colored platformer items as class-diverse training targets.
- Keep generated scene wrappers separate from vendor folders.

For perception training:

- Label characters by stable semantic class, not by raw Godot node name.
- Use platform colors and variants to diversify background geometry.
- Use props for prompt-selection, distance, occlusion, and reacquisition tests.
- Treat asset path and semantic class as separate concepts so models do not learn folder names as labels.

The current entry scene is:

```text
stelle-env/scenes/main.tscn
```

It uses:

```text
stelle-env/scripts/procedural_room_generator.gd
```

The generator creates a `20x20` starter arena from Platformer glTF models, with an open ring path for future CameraRig looping and props placed away from that loop. Treat it as an inspectable starter scene for later procedural environment systems, not as final gameplay.

Runtime preview capture scene:

```text
stelle-env/scenes/preview_capture.tscn
```

Preview output:

```text
stelle-env/screenshots/procedural_room_preview.png
```

## Extracted Content Snapshot

Combined extracted file types:

```text
.gltf: 401
.bin: 401
.png: 76
.glb: 8
.url: 6
.txt: 2
```

Use this snapshot as a quick sanity check if the asset folders are moved or regenerated later.
