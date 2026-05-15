# Quaternius Modular Sci-Fi MegaKit Standard

This document records the free Standard version of Quaternius Modular Sci-Fi MegaKit added for sci-fi arena experiments.

## Location

The extracted runtime assets are stored under:

```text
stelle-env/assets/vendor/quaternius/modular_sci_fi_megakit_standard/
```

Keep this folder as vendor content. Build generated scenes and wrappers outside the vendor folder.

## Source

- Official pack page: https://quaternius.com/packs/modularscifimegakit.html
- itch.io download page: https://quaternius.itch.io/modular-sci-fi-megakit

The pack is advertised as a grid-based modular sci-fi environment kit with FBX, OBJ, and glTF formats. The free Standard download is the `Modular SciFi MegaKit[Standard].zip` package.

## License

The extracted package includes:

```text
License_Standard.txt
```

It states the pack is the Standard free version and uses:

```text
CC0 1.0 Universal
```

Credit is optional, but recommended:

```text
Models by @Quaternius
```

## Import Format Guidance

For Godot 4, this project keeps the glTF-oriented runtime set:

- `.gltf`
- `.bin`
- `.png`
- `.txt` license file

The downloaded archive also contains FBX, OBJ, and MTL variants, but those were not copied into the Godot runtime asset folder.

The glTF files reference shared trim and decal textures by local filename. To keep Godot imports warning-free, the source textures were copied into each glTF category folder.

## Extracted Content Snapshot

Current extracted file types:

```text
.gltf: 190
.bin:  190
.png:  150
.txt:  1
```

The `.png` count includes source previews, shared textures, and copied texture files needed by glTF local URI imports.

Main glTF categories:

- `Aliens`
- `Columns`
- `Decals`
- `Platforms`
- `Props`
- `Walls`

## Visual Style Note

The reference screenshot looks like a stylized low-poly modular environment, but it is not just raw flat-color low-poly geometry. The look is closer to:

- simple low- to mid-poly modular meshes
- trim-sheet or atlas-like texture maps
- gray metal panels with blue/cyan accent strips
- emissive elements for gates, lights, paths, and UI overlays
- clean bevels and readable silhouettes instead of photoreal material complexity

So this pack is a good match for the direction: it supplies grid-based sci-fi wall, floor, platform, prop, column, decal, and alien modules with texture support. The purple teleport gates and cyan loop markers in the starter scene are generated in Godot as simple emissive geometry.

## Starter Scene

Sci-fi arena scene:

```text
stelle-env/scenes/scifi_arena.tscn
```

Generator script:

```text
stelle-env/scripts/scifi_arena_generator.gd
```

Preview capture scene:

```text
stelle-env/scenes/scifi_preview_capture.tscn
```

Preview output:

```text
stelle-env/screenshots/scifi_arena_preview.png
```

The scene creates a `20x20` grid arena with:

- tiled sci-fi floor
- an open loop lane for future CameraRig movement
- perimeter wall stacks
- cover clusters and props
- landmark objects
- cyan loop markers
- purple teleport gates

Treat this as a style and asset-integration prototype, not final gameplay.

## Suggested TAO-NOT-42 Usage

Use this pack for:

- sci-fi arena variants
- indoor/corridor-like generated scenes
- occlusion and reacquisition tests
- prompt targets and distractors from props, aliens, columns, and decals
- visual diversity against the brighter KayKit platformer arena

Do not let model labels depend on raw vendor filenames. Map these assets to stable semantic classes in future Godot-side dataset recording.
