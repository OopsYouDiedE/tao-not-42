extends Node3D

const PLATFORMER_ROOT := "res://assets/vendor/kaykit/KayKit_Platformer_Pack_1.0_FREE/Assets/gltf"
const FLOOR_TILE_MATERIAL_PATH := "res://assets/sci-lowpoly/texture/granite_tile_04_1k.material"
const WALL_CENTER_MATERIAL_PATH := "res://assets/sci-lowpoly/texture/concrete_tiles_02_1k.material"
const WALL_TRIM_MATERIAL_PATH := "res://assets/sci-lowpoly/texture/granite_tile_dark_1k.material"
const FLAG_ALBEDO_TEXTURE_PATH := "res://assets/sci-lowpoly/texture/flag_blue_gold/flag_blue_gold_albedo.png"
const FLAG_METALLIC_TEXTURE_PATH := "res://assets/sci-lowpoly/texture/flag_blue_gold/flag_blue_gold_metallic.png"
const FLAG_NORMAL_TEXTURE_PATH := "res://assets/sci-lowpoly/texture/crepe_satin_1k/textures/crepe_satin_nor_gl_1k.jpg"
const GENERATED_GROUP := "scifi_arena_generated"

@export var seed: int = 872341
@export var grid_width: int = 20
@export var grid_depth: int = 20
@export var tile_spacing: float = 1.0
@export var loop_margin_tiles: int = 1
@export var loop_waypoint_count: int = 20

var _rng := RandomNumberGenerator.new()
var _materials := {}


func _ready() -> void:
	generate_arena()


func generate_arena() -> void:
	_clear_generated()
	_rng.seed = seed
	_build_materials()

	var root := Node3D.new()
	root.name = "GeneratedSciFiArena"
	root.add_to_group(GENERATED_GROUP)
	add_child(root)

	_build_floor(root)
	_build_boundary_walls(root)
	_build_platform_layout(root)
	_build_archways(root)
	_build_ramps(root)
	_build_training_props(root)
	_build_targets(root)
	_build_bot_and_drones(root)
	_build_teleport_gates(root)
	_build_debug_loop_path(root)
	_build_camera()
	_build_debug_overlay()


func _build_materials() -> void:
	_materials = {
		"floor_a": _make_material(Color(0.50, 0.49, 0.46), 0.82, 0.0),
		"floor_b": _make_material(Color(0.45, 0.45, 0.43), 0.88, 0.0),
		"wall": _make_material(Color(0.36, 0.36, 0.35), 0.78, 0.0),
		"wall_dark": _make_material(Color(0.22, 0.23, 0.23), 0.82, 0.0),
		"cap": _make_material(Color(0.64, 0.61, 0.56), 0.72, 0.0),
		"blue": _make_material(Color(0.13, 0.31, 0.55), 0.62, 0.0),
		"blue_glow": _make_material(Color(0.10, 0.42, 1.0), 0.30, 2.4),
		"tan": _make_material(Color(0.18, 0.38, 0.72), 0.58, 0.0),
		"wood": _make_material(Color(0.45, 0.25, 0.11), 0.72, 0.0),
		"black": _make_material(Color(0.03, 0.035, 0.04), 0.55, 0.0),
		"white": _make_material(Color(0.82, 0.82, 0.78), 0.45, 0.0),
		"red": _make_material(Color(0.96, 0.18, 0.12), 0.48, 0.0),
		"blue_target": _make_material(Color(0.1, 0.35, 0.95), 0.42, 0.0),
		"green": _make_material(Color(0.28, 0.66, 0.34), 0.55, 0.0),
		"cyan": _make_material(Color(0.0, 0.82, 0.88), 0.3, 1.1),
		"waypoint": _make_material(Color(0.30, 0.72, 0.34), 0.45, 0.6),
		"purple": _make_material(Color(0.74, 0.20, 1.0), 0.2, 5.0),
		"purple_glass": _make_material(Color(0.58, 0.12, 0.9, 0.36), 0.18, 1.5, BaseMaterial3D.TRANSPARENCY_ALPHA),
		"magenta": _make_material(Color(1.0, 0.13, 0.82), 0.18, 5.5),
		"orange": _make_material(Color(1.0, 0.62, 0.08), 0.45, 0.7),
		"metal": _make_material(Color(0.55, 0.55, 0.52), 0.34, 0.0),
		"flag_blue": _make_flag_material(),
	}

	var floor_material_resource: Resource = load(FLOOR_TILE_MATERIAL_PATH)
	if floor_material_resource is Material:
		_materials["floor_tile"] = floor_material_resource as Material
	else:
		push_warning("Could not load floor tile material: %s" % FLOOR_TILE_MATERIAL_PATH)

	var wall_center_material_resource: Resource = load(WALL_CENTER_MATERIAL_PATH)
	if wall_center_material_resource is Material:
		_materials["wall_center_tile"] = wall_center_material_resource as Material
	else:
		push_warning("Could not load wall center material: %s" % WALL_CENTER_MATERIAL_PATH)

	var wall_trim_material_resource: Resource = load(WALL_TRIM_MATERIAL_PATH)
	if wall_trim_material_resource is Material:
		_materials["wall_trim_tile"] = wall_trim_material_resource as Material
	else:
		push_warning("Could not load wall trim material: %s" % WALL_TRIM_MATERIAL_PATH)


func _build_floor(parent: Node3D) -> void:
	var floor_material: Material = _floor_tile_material()
	for x in range(grid_width):
		for z in range(grid_depth):
			_add_box(parent, _grid_position(x, z, -0.04), Vector3(1.005, 0.08, 1.005), floor_material)


func _build_boundary_walls(parent: Node3D) -> void:
	for x in range(grid_width):
		if not _is_gate_gap(x, 0):
			_add_wall_cell(parent, x, 0, 0.0, x % 5 == 2)
		if not _is_gate_gap(x, grid_depth - 1):
			_add_wall_cell(parent, x, grid_depth - 1, PI, x % 5 == 2)

	for z in range(1, grid_depth - 1):
		if not _is_gate_gap(0, z):
			_add_wall_cell(parent, 0, z, PI * 0.5, z % 5 == 2)
		if not _is_gate_gap(grid_width - 1, z):
			_add_wall_cell(parent, grid_width - 1, z, -PI * 0.5, z % 5 == 2)

	for corner in [Vector2i(0, 0), Vector2i(grid_width - 1, 0), Vector2i(0, grid_depth - 1), Vector2i(grid_width - 1, grid_depth - 1)]:
		_add_box(parent, _grid_position(corner.x, corner.y, 1.90), Vector3(1.18, 3.8, 1.18), _wall_center_material())
		_add_box(parent, _grid_position(corner.x, corner.y, 0.18), Vector3(1.3, 0.24, 1.3), _wall_trim_material())
		_add_box(parent, _grid_position(corner.x, corner.y, 3.66), Vector3(1.3, 0.26, 1.3), _wall_trim_material())


func _add_wall_cell(parent: Node3D, x: int, z: int, y_rot: float, banner: bool) -> void:
	var p := _grid_position(x, z, 0.0)
	var wall_bottom_y := 0.18
	var wall_height := 1.76
	var wall_top_y := wall_bottom_y + wall_height
	_add_box(parent, p + Vector3(0.0, wall_bottom_y + wall_height * 0.5, 0.0), Vector3(0.94, wall_height, 0.24), _wall_center_material(), Vector3(0.0, y_rot, 0.0))
	_add_box(parent, p + Vector3(0.0, 0.17, 0.0), Vector3(1.04, 0.22, 0.34), _wall_trim_material(), Vector3(0.0, y_rot, 0.0))
	_add_box(parent, p + Vector3(0.0, wall_top_y + 0.04, 0.0), Vector3(1.04, 0.20, 0.34), _wall_trim_material(), Vector3(0.0, y_rot, 0.0))
	_add_box(parent, p + Vector3(0.0, wall_bottom_y + wall_height * 0.8, 0.0), Vector3(0.96, 0.07, 0.285), _materials["blue_glow"], Vector3(0.0, y_rot, 0.0))

	if banner:
		_add_wall_flag(parent, p, y_rot, wall_top_y)


func _add_wall_flag(parent: Node3D, wall_position: Vector3, y_rot: float, wall_top_y: float) -> void:
	var outward := _wall_outward(y_rot)
	var rod_y := wall_top_y + 0.04
	var flag_y := rod_y - 0.42
	var flag := MeshInstance3D.new()
	flag.name = "HangingFlag"
	flag.mesh = _make_hanging_flag_mesh()
	flag.material_override = _materials["flag_blue"]
	flag.position = wall_position + outward * 0.205 + Vector3(0.0, flag_y, 0.0)
	flag.rotation = Vector3(0.0, y_rot, 0.0)
	flag.add_to_group(GENERATED_GROUP)
	parent.add_child(flag)

	_add_box(parent, wall_position + outward * 0.225 + Vector3(0.0, rod_y, 0.0), Vector3(0.64, 0.055, 0.065), _wall_trim_material(), Vector3(0.0, y_rot, 0.0))
	_add_box(parent, wall_position + outward * 0.235 + Vector3(0.0, flag_y + 0.24, 0.0), Vector3(0.20, 0.20, 0.035), _wall_trim_material(), Vector3(0.0, y_rot + PI * 0.25, 0.0))


func _build_platform_layout(parent: Node3D) -> void:
	_add_platform_rect(parent, 3, 3, 4, 3, 1.05)
	_add_platform_rect(parent, 8, 3, 4, 2, 1.35)
	_add_platform_rect(parent, 13, 3, 4, 3, 1.05)
	_add_platform_rect(parent, 6, 8, 4, 3, 0.82)
	_add_platform_rect(parent, 11, 8, 4, 3, 1.18)
	_add_platform_rect(parent, 3, 13, 3, 3, 0.72)
	_add_platform_rect(parent, 9, 14, 3, 3, 0.92)
	_add_platform_rect(parent, 15, 13, 3, 3, 0.82)

	_add_inner_wall(parent, 7, 6, 5, true)
	_add_inner_wall(parent, 12, 6, 4, true)
	_add_inner_wall(parent, 5, 11, 4, false)
	_add_inner_wall(parent, 14, 10, 4, false)
	_add_column_group(parent)


func _build_archways(parent: Node3D) -> void:
	_add_archway(parent, Vector2i(9, 6), 0.0, 1.65)
	_add_archway(parent, Vector2i(10, 12), PI, 1.45)
	_add_archway(parent, Vector2i(4, 9), PI * 0.5, 1.35)
	_add_archway(parent, Vector2i(15, 9), -PI * 0.5, 1.35)
	_add_archway(parent, Vector2i(10, 4), PI * 0.5, 1.55)


func _add_archway(parent: Node3D, cell: Vector2i, y_rot: float, height: float) -> void:
	var p := _grid_position(cell.x, cell.y, 0.0)
	var center_material := _wall_center_material()
	var trim_material := _wall_trim_material()
	_add_box(parent, p + _yaw_offset(Vector3(-0.46, height * 0.5, 0.0), y_rot), Vector3(0.22, height, 0.36), center_material, Vector3(0.0, y_rot, 0.0))
	_add_box(parent, p + _yaw_offset(Vector3(0.46, height * 0.5, 0.0), y_rot), Vector3(0.22, height, 0.36), center_material, Vector3(0.0, y_rot, 0.0))
	_add_box(parent, p + _yaw_offset(Vector3(0.0, height + 0.14, 0.0), y_rot), Vector3(1.18, 0.28, 0.40), trim_material, Vector3(0.0, y_rot, 0.0))
	_add_box(parent, p + _yaw_offset(Vector3(0.0, height + 0.33, 0.0), y_rot), Vector3(1.30, 0.12, 0.46), _materials["blue_glow"], Vector3(0.0, y_rot, 0.0))
	_add_box(parent, p + _yaw_offset(Vector3(-0.46, 0.16, 0.0), y_rot), Vector3(0.30, 0.22, 0.44), trim_material, Vector3(0.0, y_rot, 0.0))
	_add_box(parent, p + _yaw_offset(Vector3(0.46, 0.16, 0.0), y_rot), Vector3(0.30, 0.22, 0.44), trim_material, Vector3(0.0, y_rot, 0.0))


func _add_platform_rect(parent: Node3D, x0: int, z0: int, w: int, d: int, h: float) -> void:
	var top_material: Material = _floor_tile_material()
	for x in range(x0, x0 + w):
		for z in range(z0, z0 + d):
			var p := _grid_position(x, z, 0.0)
			_add_box(parent, p + Vector3(0.0, h * 0.5, 0.0), Vector3(0.88, h, 0.88), _wall_center_material())
			_add_box(parent, p + Vector3(0.0, 0.08, 0.0), Vector3(0.96, 0.16, 0.96), _wall_trim_material())
			_add_box(parent, p + Vector3(0.0, h - 0.08, 0.0), Vector3(0.96, 0.16, 0.96), _wall_trim_material())
			_add_box(parent, p + Vector3(0.0, h + 0.055, 0.0), Vector3(0.96, 0.11, 0.96), top_material)

	for x in range(x0, x0 + w):
		_add_box(parent, _grid_position(x, z0, h + 0.18), Vector3(0.84, 0.12, 0.08), _materials["blue_glow"])
		_add_box(parent, _grid_position(x, z0 + d - 1, h + 0.18), Vector3(0.84, 0.12, 0.08), _materials["blue_glow"])
	for z in range(z0, z0 + d):
		_add_box(parent, _grid_position(x0, z, h + 0.18), Vector3(0.08, 0.12, 0.84), _materials["blue_glow"])
		_add_box(parent, _grid_position(x0 + w - 1, z, h + 0.18), Vector3(0.08, 0.12, 0.84), _materials["blue_glow"])


func _add_inner_wall(parent: Node3D, x: int, z: int, length: int, horizontal: bool) -> void:
	for i in range(length):
		var cell := Vector2i(x + i, z) if horizontal else Vector2i(x, z + i)
		var rot := 0.0 if horizontal else PI * 0.5
		_add_box(parent, _grid_position(cell.x, cell.y, 0.55), Vector3(0.90, 0.76, 0.20), _wall_center_material(), Vector3(0.0, rot, 0.0))
		_add_box(parent, _grid_position(cell.x, cell.y, 0.15), Vector3(0.98, 0.18, 0.30), _wall_trim_material(), Vector3(0.0, rot, 0.0))
		_add_box(parent, _grid_position(cell.x, cell.y, 0.96), Vector3(0.98, 0.16, 0.30), _wall_trim_material(), Vector3(0.0, rot, 0.0))
		_add_box(parent, _grid_position(cell.x, cell.y, 0.78), Vector3(0.92, 0.06, 0.25), _materials["blue_glow"], Vector3(0.0, rot, 0.0))


func _add_column_group(parent: Node3D) -> void:
	for cell in [Vector2i(4, 7), Vector2i(6, 7), Vector2i(13, 7), Vector2i(15, 7), Vector2i(8, 12), Vector2i(12, 13)]:
		_add_box(parent, _grid_position(cell.x, cell.y, 0.62), Vector3(0.42, 1.24, 0.42), _materials["wall_dark"])
		_add_box(parent, _grid_position(cell.x, cell.y, 1.28), Vector3(0.52, 0.16, 0.52), _materials["cap"])


func _build_ramps(parent: Node3D) -> void:
	_add_ramp(parent, Vector2i(6, 5), Vector2i(8, 7), 1.05, PI * 0.25)
	_add_ramp(parent, Vector2i(10, 11), Vector2i(8, 13), 0.92, -PI * 0.25)
	_add_ramp(parent, Vector2i(15, 6), Vector2i(14, 8), 1.05, -PI * 0.32)
	_add_ramp(parent, Vector2i(12, 12), Vector2i(15, 14), 0.82, PI * 0.25)


func _add_ramp(parent: Node3D, from_cell: Vector2i, to_cell: Vector2i, height: float, roll: float) -> void:
	var a := _grid_position(from_cell.x, from_cell.y, 0.12)
	var b := _grid_position(to_cell.x, to_cell.y, height)
	var delta := b - a
	var center := (a + b) * 0.5
	var length := Vector2(delta.x, delta.z).length() + 0.9
	var yaw := atan2(delta.x, delta.z)
	_add_box(parent, center, Vector3(0.86, 0.16, length), _materials["tan"], Vector3(roll, yaw, 0.0))
	_add_box(parent, center + Vector3(0.0, 0.08, 0.0), Vector3(0.92, 0.06, length + 0.08), _materials["blue"], Vector3(roll, yaw, 0.0))


func _build_training_props(parent: Node3D) -> void:
	for cell in [Vector2i(2, 11), Vector2i(4, 12), Vector2i(14, 4), Vector2i(16, 14), Vector2i(8, 16)]:
		_add_crate_stack(parent, cell, _rng.randi_range(1, 3))

	for cell in [Vector2i(3, 15), Vector2i(16, 11), Vector2i(2, 6), Vector2i(17, 16)]:
		_add_spike_trap(parent, cell)

	for cell in [Vector2i(5, 5), Vector2i(10, 10), Vector2i(15, 15), Vector2i(13, 5)]:
		_add_pressure_plate(parent, cell)

	for cell in [Vector2i(3, 13), Vector2i(16, 6)]:
		_spawn_kaykit(parent, "blue/lever_floor_base_blue.gltf", _grid_position(cell.x, cell.y, 0.04), Vector3.ZERO, Vector3.ONE * 0.23)

	for cell in [Vector2i(6, 15), Vector2i(12, 4)]:
		_add_projectile_beam(parent, cell)

	_add_pendulum(parent, Vector2i(10, 7))
	_add_tree_cluster(parent, Vector2i(9, 13))
	_add_tree_cluster(parent, Vector2i(13, 9))


func _add_crate_stack(parent: Node3D, cell: Vector2i, count: int) -> void:
	for i in range(count):
		var p := _grid_position(cell.x, cell.y, 0.22 + float(i) * 0.46)
		_add_box(parent, p, Vector3(0.58, 0.44, 0.58), _materials["wood"])
		_add_box(parent, p + Vector3(0.0, 0.01, 0.0), Vector3(0.64, 0.05, 0.08), _materials["cap"], Vector3(0.0, PI * 0.25, 0.0))
		_add_box(parent, p + Vector3(0.0, -0.01, 0.0), Vector3(0.08, 0.05, 0.64), _materials["cap"], Vector3(0.0, PI * 0.25, 0.0))


func _add_spike_trap(parent: Node3D, cell: Vector2i) -> void:
	var base := _grid_position(cell.x, cell.y, 0.04)
	_add_box(parent, base, Vector3(0.92, 0.08, 0.92), _materials["wall_dark"])
	for ix in range(3):
		for iz in range(3):
			var offset := Vector3((float(ix) - 1.0) * 0.24, 0.18, (float(iz) - 1.0) * 0.24)
			_add_cone(parent, base + offset, 0.09, 0.35, _materials["metal"])


func _add_pressure_plate(parent: Node3D, cell: Vector2i) -> void:
	var p := _grid_position(cell.x, cell.y, 0.06)
	_add_box(parent, p, Vector3(0.82, 0.08, 0.82), _materials["blue"])
	_add_box(parent, p + Vector3(0.0, 0.055, 0.0), Vector3(0.48, 0.04, 0.48), _materials["tan"])


func _add_projectile_beam(parent: Node3D, cell: Vector2i) -> void:
	var p := _grid_position(cell.x, cell.y, 0.72)
	_add_sphere(parent, p, 0.16, _materials["magenta"])
	_add_box(parent, p + Vector3(0.42, 0.0, 0.0), Vector3(0.85, 0.055, 0.055), _materials["magenta"])


func _add_pendulum(parent: Node3D, cell: Vector2i) -> void:
	var p := _grid_position(cell.x, cell.y, 0.0)
	_add_cylinder(parent, p + Vector3(0.0, 1.65, 0.0), 0.04, 1.8, _materials["metal"], Vector3(0.45, 0.0, 0.0))
	_add_sphere(parent, p + Vector3(0.0, 0.68, 0.48), 0.28, _materials["red"])
	_add_box(parent, p + Vector3(0.0, 0.68, 0.48), Vector3(0.38, 0.08, 0.38), _materials["white"])


func _add_tree_cluster(parent: Node3D, cell: Vector2i) -> void:
	var p := _grid_position(cell.x, cell.y, 0.0)
	_add_box(parent, p + Vector3(0.0, 0.08, 0.0), Vector3(0.82, 0.16, 0.82), _materials["wall"])
	_add_cylinder(parent, p + Vector3(0.0, 0.38, 0.0), 0.10, 0.58, _materials["wood"])
	_add_cone(parent, p + Vector3(0.0, 0.78, 0.0), 0.42, 0.72, _materials["green"])
	_add_cone(parent, p + Vector3(0.0, 1.12, 0.0), 0.32, 0.58, _materials["green"])


func _build_targets(parent: Node3D) -> void:
	_add_humanoid(parent, _grid_position(5, 4, 1.25), _materials["red"], "ID: 9")
	_add_humanoid(parent, _grid_position(14, 4, 1.25), _materials["blue_target"], "ID: 13")
	_add_humanoid(parent, _grid_position(13, 9, 1.35), _materials["red"], "ID: 12")
	_add_humanoid(parent, _grid_position(7, 15, 0.95), _materials["red"], "ID: 2")
	_add_humanoid(parent, _grid_position(3, 8, 0.1), _materials["blue_target"], "ID: 6")


func _add_humanoid(parent: Node3D, position: Vector3, material: Material, label_text: String) -> void:
	var root := Node3D.new()
	root.name = "HumanoidTarget"
	root.position = position
	root.add_to_group(GENERATED_GROUP)
	parent.add_child(root)
	_add_cylinder(root, Vector3(0.0, 0.48, 0.0), 0.16, 0.72, material)
	_add_sphere(root, Vector3(0.0, 0.92, 0.0), 0.16, material)
	_add_cylinder(root, Vector3(-0.22, 0.42, 0.0), 0.055, 0.58, material, Vector3(0.0, 0.0, 0.2))
	_add_cylinder(root, Vector3(0.22, 0.42, 0.0), 0.055, 0.58, material, Vector3(0.0, 0.0, -0.2))
	_add_cylinder(root, Vector3(-0.09, 0.06, 0.0), 0.06, 0.52, material)
	_add_cylinder(root, Vector3(0.09, 0.06, 0.0), 0.06, 0.52, material)
	_add_label(parent, label_text, position + Vector3(0.0, 1.22, 0.0), Color(0.35, 1.0, 0.35), 0.014)


func _build_bot_and_drones(parent: Node3D) -> void:
	_add_camera_bot(parent, _grid_position(10, 18, 0.16))
	for p in [
		_grid_position(4, 7, 2.4),
		_grid_position(11, 8, 2.55),
		_grid_position(15, 3, 2.55),
		_grid_position(17, 5, 2.45),
	]:
		_add_drone(parent, p)


func _add_camera_bot(parent: Node3D, position: Vector3) -> void:
	var root := Node3D.new()
	root.name = "CameraRigBot"
	root.position = position
	root.add_to_group(GENERATED_GROUP)
	parent.add_child(root)
	_add_box(root, Vector3(0.0, 0.18, 0.0), Vector3(0.92, 0.28, 0.72), _materials["white"])
	_add_box(root, Vector3(0.0, 0.38, 0.0), Vector3(0.48, 0.22, 0.38), _materials["black"])
	_add_cylinder(root, Vector3(-0.42, 0.04, -0.28), 0.13, 0.16, _materials["black"], Vector3(PI * 0.5, 0.0, 0.0))
	_add_cylinder(root, Vector3(0.42, 0.04, -0.28), 0.13, 0.16, _materials["black"], Vector3(PI * 0.5, 0.0, 0.0))
	_add_cylinder(root, Vector3(-0.42, 0.04, 0.28), 0.13, 0.16, _materials["black"], Vector3(PI * 0.5, 0.0, 0.0))
	_add_cylinder(root, Vector3(0.42, 0.04, 0.28), 0.13, 0.16, _materials["black"], Vector3(PI * 0.5, 0.0, 0.0))
	_add_sphere(root, Vector3(0.0, 0.58, -0.08), 0.16, _materials["black"])
	_add_box(root, Vector3(0.0, 0.58, -0.25), Vector3(0.36, 0.2, 0.16), _materials["black"])


func _add_drone(parent: Node3D, position: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Drone"
	root.position = position
	root.add_to_group(GENERATED_GROUP)
	parent.add_child(root)
	_add_box(root, Vector3.ZERO, Vector3(0.42, 0.12, 0.28), _materials["black"])
	_add_sphere(root, Vector3(0.0, -0.02, -0.16), 0.06, _materials["red"])
	for offset in [Vector3(-0.35, 0.0, -0.26), Vector3(0.35, 0.0, -0.26), Vector3(-0.35, 0.0, 0.26), Vector3(0.35, 0.0, 0.26)]:
		_add_box(root, offset * 0.55, Vector3(0.38, 0.035, 0.035), _materials["black"], Vector3(0.0, atan2(offset.x, offset.z), 0.0))
		_add_cylinder(root, offset, 0.16, 0.025, _materials["black"])


func _build_teleport_gates(parent: Node3D) -> void:
	var gates := [
		[Vector2i(10, 0), 0.0],
		[Vector2i(10, grid_depth - 1), PI],
		[Vector2i(0, 10), PI * 0.5],
		[Vector2i(grid_width - 1, 10), -PI * 0.5],
	]

	for gate in gates:
		var cell: Vector2i = gate[0]
		var rot_y: float = gate[1]
		var root := Node3D.new()
		root.name = "TeleportGate"
		root.position = _grid_position(cell.x, cell.y, 0.0)
		root.rotation.y = rot_y
		root.add_to_group(GENERATED_GROUP)
		parent.add_child(root)
		_add_box(root, Vector3(0.0, 0.015, -0.62), Vector3(1.35, 0.03, 0.9), _materials["purple_glass"])
		_add_box(root, Vector3(-0.5, 0.75, -0.18), Vector3(0.08, 1.5, 0.08), _materials["purple"])
		_add_box(root, Vector3(0.5, 0.75, -0.18), Vector3(0.08, 1.5, 0.08), _materials["purple"])
		_add_box(root, Vector3(0.0, 1.46, -0.18), Vector3(1.08, 0.08, 0.08), _materials["purple"])
		_add_box(root, Vector3(0.0, 0.75, -0.2), Vector3(0.84, 1.24, 0.035), _materials["purple_glass"])
		_add_box(root, Vector3(0.0, 0.04, -0.64), Vector3(0.6, 0.05, 0.08), _materials["purple"])
		_add_box(root, Vector3(0.0, 0.04, -0.64), Vector3(0.08, 0.05, 0.42), _materials["purple"])


func _build_debug_loop_path(parent: Node3D) -> void:
	var points := _loop_points()
	for i in range(points.size()):
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % points.size()]
		_add_dashed_segment(parent, a, b)
		_add_waypoint(parent, i + 1, a)


func _loop_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var min_x := loop_margin_tiles
	var max_x := grid_width - loop_margin_tiles - 1
	var min_z := loop_margin_tiles
	var max_z := grid_depth - loop_margin_tiles - 1
	var per_side := int(loop_waypoint_count / 4)

	for i in range(per_side):
		points.append(_grid_position(min_x + i * int((max_x - min_x) / max(1, per_side - 1)), min_z, 0.11))
	for i in range(per_side):
		points.append(_grid_position(max_x, min_z + i * int((max_z - min_z) / max(1, per_side - 1)), 0.11))
	for i in range(per_side):
		points.append(_grid_position(max_x - i * int((max_x - min_x) / max(1, per_side - 1)), max_z, 0.11))
	for i in range(per_side):
		points.append(_grid_position(min_x, max_z - i * int((max_z - min_z) / max(1, per_side - 1)), 0.11))

	return points


func _add_dashed_segment(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var delta := b - a
	var length := Vector2(delta.x, delta.z).length()
	var dir := Vector3(delta.x, 0.0, delta.z).normalized()
	var yaw := atan2(delta.x, delta.z)
	var dash_count: int = max(1, int(length / 0.38))
	for i in range(dash_count):
		if i % 2 == 1:
			continue
		var t := (float(i) + 0.5) / float(dash_count)
		var center := a.lerp(b, t)
		_add_box(parent, center, Vector3(0.035, 0.035, min(0.25, length / float(dash_count))), _materials["cyan"], Vector3(0.0, yaw, 0.0))
		if i % 6 == 0:
			_add_cone(parent, center + dir * 0.18 + Vector3(0.0, 0.04, 0.0), 0.09, 0.18, _materials["cyan"], Vector3(PI * 0.5, yaw, 0.0))


func _add_waypoint(parent: Node3D, index: int, position: Vector3) -> void:
	_add_cylinder(parent, position + Vector3(0.0, 0.04, 0.0), 0.16, 0.035, _materials["waypoint"])
	_add_label(parent, str(index), position + Vector3(0.0, 0.12, 0.0), Color.WHITE, 0.018)


func _build_camera() -> void:
	if has_node("Camera3D"):
		return

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 18.0, 18.5)
	camera.rotation_degrees = Vector3(-52.0, 0.0, 0.0)
	camera.fov = 42.0
	camera.current = true
	add_child(camera)


func _build_debug_overlay() -> void:
	if has_node("DebugOverlay"):
		return

	var layer := CanvasLayer.new()
	layer.name = "DebugOverlay"
	add_child(layer)

	_add_overlay_panel(
		layer,
		Vector2(10.0, 10.0),
		Vector2(210.0, 214.0),
		"ARENA CONFIG\n\nGrid Size        20 x 20\nTile Size        1.0 m\nArena Size       20.0 m x 20.0 m\nBoundary         Teleport Gates\nLoop Path        Ring (Clockwise)\nSeed             872341\n\n        Regenerate Arena"
	)
	_add_overlay_panel(
		layer,
		Vector2(10.0, 540.0),
		Vector2(186.0, 340.0),
		"LEGEND\n\n● Waypoint\n→ Path Direction\n▣ Teleport Gate\n● Humanoid Target\n◇ Object Target\n▣ CameraRig (Bot)\n● Spring Pad\n▣ Pressure Plate\n▌ Lever Switch\n▲ Spikes\n● Projectile (Live)\n✣ Drone (Live)"
	)
	_add_overlay_panel(
		layer,
		Vector2(1368.0, 10.0),
		Vector2(222.0, 168.0),
		"DEBUG OVERLAY\n\n☑ Show Waypoints\n☑ Show Path\n☑ Show Teleport Gates\n☑ Show Targets\n☑ Show Traps\n\nFPS: 60"
	)
	_add_overlay_panel(
		layer,
		Vector2(1410.0, 730.0),
		Vector2(180.0, 162.0),
		"CONTROLS\n\nR   Regenerate\nT   Toggle Overlay\n1   Next Camera\n2   Follow Bot\nEsc Free Camera"
	)


func _add_overlay_panel(parent: CanvasLayer, position: Vector2, size: Vector2, text: String) -> void:
	var panel := ColorRect.new()
	panel.position = position
	panel.size = size
	panel.color = Color(0.02, 0.025, 0.035, 0.72)
	panel.add_to_group(GENERATED_GROUP)
	parent.add_child(panel)

	var label := Label.new()
	label.position = position + Vector2(12.0, 10.0)
	label.size = size - Vector2(24.0, 20.0)
	label.text = text
	label.modulate = Color(0.92, 0.94, 0.96)
	label.add_theme_font_size_override("font_size", 13)
	label.add_to_group(GENERATED_GROUP)
	parent.add_child(label)


func _spawn_kaykit(parent: Node3D, relative_path: String, position: Vector3, rotation: Vector3, scale: Vector3) -> Node3D:
	var scene: Resource = load("%s/%s" % [PLATFORMER_ROOT, relative_path])
	if not scene is PackedScene:
		push_warning("Could not load KayKit asset: %s" % relative_path)
		return null

	var packed_scene := scene as PackedScene
	var instance: Node = packed_scene.instantiate()
	if instance is Node3D:
		instance.position = position
		instance.rotation = rotation
		instance.scale = scale
		instance.add_to_group(GENERATED_GROUP)
		parent.add_child(instance)
		return instance

	instance.queue_free()
	return null


func _add_box(parent: Node3D, position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position
	mesh_instance.rotation = rotation
	mesh_instance.add_to_group(GENERATED_GROUP)
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_cylinder(parent: Node3D, position: Vector3, radius: float, height: float, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position
	mesh_instance.rotation = rotation
	mesh_instance.add_to_group(GENERATED_GROUP)
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_cone(parent: Node3D, position: Vector3, radius: float, height: float, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position
	mesh_instance.rotation = rotation
	mesh_instance.add_to_group(GENERATED_GROUP)
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_sphere(parent: Node3D, position: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position
	mesh_instance.add_to_group(GENERATED_GROUP)
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_label(parent: Node3D, text: String, position: Vector3, color: Color, pixel_size: float = 0.024) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.pixel_size = pixel_size
	label.position = position
	label.rotation_degrees = Vector3(-62.0, 0.0, 0.0)
	label.add_to_group(GENERATED_GROUP)
	parent.add_child(label)
	return label


func _make_material(color: Color, roughness: float, emission_energy: float, transparency: int = BaseMaterial3D.TRANSPARENCY_DISABLED) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	material.transparency = transparency
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material


func _make_flag_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.roughness = 0.46
	material.metallic = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var albedo_resource: Resource = load(FLAG_ALBEDO_TEXTURE_PATH)
	if albedo_resource is Texture2D:
		material.albedo_texture = albedo_resource as Texture2D

	var metallic_resource: Resource = load(FLAG_METALLIC_TEXTURE_PATH)
	if metallic_resource is Texture2D:
		material.metallic_texture = metallic_resource as Texture2D

	var normal_resource: Resource = load(FLAG_NORMAL_TEXTURE_PATH)
	if normal_resource is Texture2D:
		material.normal_enabled = true
		material.normal_texture = normal_resource as Texture2D

	return material


func _make_hanging_flag_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-0.30, 0.42, 0.0),
		Vector3(0.30, 0.42, 0.0),
		Vector3(0.30, -0.78, 0.0),
		Vector3(0.0, -1.26, 0.0),
		Vector3(-0.30, -0.78, 0.0),
	])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 0.0, 1.0),
	])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(1.0, 0.74),
		Vector2(0.5, 1.0),
		Vector2(0.0, 0.74),
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 4, 4, 2, 3])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _floor_tile_material() -> Material:
	if _materials.has("floor_tile"):
		return _materials["floor_tile"] as Material

	return _materials["floor_a"] as Material


func _wall_center_material() -> Material:
	if _materials.has("wall_center_tile"):
		return _materials["wall_center_tile"] as Material

	return _materials["wall"] as Material


func _wall_trim_material() -> Material:
	if _materials.has("wall_trim_tile"):
		return _materials["wall_trim_tile"] as Material

	return _materials["wall_dark"] as Material


func _clear_generated() -> void:
	for node in get_tree().get_nodes_in_group(GENERATED_GROUP):
		if is_instance_valid(node):
			node.queue_free()


func _grid_position(x: int, z: int, y: float) -> Vector3:
	return Vector3(_grid_x(x), y, _grid_z(z))


func _grid_x(x: int) -> float:
	return (float(x) - (float(grid_width) - 1.0) * 0.5) * tile_spacing


func _grid_z(z: int) -> float:
	return (float(z) - (float(grid_depth) - 1.0) * 0.5) * tile_spacing


func _grid_min_x() -> float:
	return _grid_x(0)


func _grid_min_z() -> float:
	return _grid_z(0)


func _is_gate_gap(x: int, z: int) -> bool:
	var mid_x := int(grid_width / 2)
	var mid_z := int(grid_depth / 2)
	var on_horizontal_gate: bool = (z == 0 or z == grid_depth - 1) and abs(x - mid_x) <= 1
	var on_vertical_gate: bool = (x == 0 or x == grid_width - 1) and abs(z - mid_z) <= 1
	return on_horizontal_gate or on_vertical_gate


func _wall_outward(y_rot: float) -> Vector3:
	return Vector3(sin(y_rot), 0.0, cos(y_rot))


func _yaw_offset(offset: Vector3, y_rot: float) -> Vector3:
	return Vector3(
		offset.x * cos(y_rot) + offset.z * sin(y_rot),
		offset.y,
		-offset.x * sin(y_rot) + offset.z * cos(y_rot)
	)
