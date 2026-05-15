extends Node3D

const PLATFORMER_ROOT := "res://assets/vendor/kaykit/KayKit_Platformer_Pack_1.0_FREE/Assets/gltf"
const GENERATED_GROUP := "procedural_room_generated"

@export var seed: int = 42
@export var room_width: int = 20
@export var room_depth: int = 20
@export var tile_spacing: float = 4.0
@export var wall_height: float = 1.0
@export var loop_margin_tiles: int = 3
@export var loop_width_tiles: int = 2
@export var obstacle_count: int = 34

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	generate_room()


func generate_room() -> void:
	_clear_generated()
	_rng.seed = seed

	var root := Node3D.new()
	root.name = "GeneratedRoom"
	root.add_to_group(GENERATED_GROUP)
	add_child(root)

	_build_floor(root)
	_build_loop_surface(root)
	_build_boundary(root)
	_build_loop_markers(root)
	_build_center_terrain(root)
	_build_obstacles(root)
	_build_landmarks(root)
	_build_lighting()
	_build_camera()


func _build_floor(parent: Node3D) -> void:
	var floor_scene := _load_asset("neutral/floor_wood_4x4.gltf")
	if floor_scene == null:
		floor_scene = _load_asset("blue/platform_4x4x1_blue.gltf")

	for x in range(room_width):
		for z in range(room_depth):
			_spawn(parent, floor_scene, _grid_position(x, z, 0.0), Vector3.ZERO)


func _build_loop_surface(parent: Node3D) -> void:
	var colors := ["blue", "green", "yellow", "red"]
	for x in range(room_width):
		for z in range(room_depth):
			if not _is_on_loop_lane(x, z):
				continue

			var color: String = colors[(x + z) % colors.size()]
			var scene := _load_asset("%s/platform_4x4x1_%s.gltf" % [color, color])
			if scene == null:
				continue

			_spawn(parent, scene, _grid_position(x, z, 0.08), Vector3.ZERO)


func _build_boundary(parent: Node3D) -> void:
	var colors := ["blue", "green", "red", "yellow"]
	for x in range(room_width):
		_spawn_boundary_piece(parent, x, 0, colors[x % colors.size()])
		_spawn_boundary_piece(parent, x, room_depth - 1, colors[(x + 1) % colors.size()])

	for z in range(1, room_depth - 1):
		_spawn_boundary_piece(parent, 0, z, colors[(z + 2) % colors.size()], PI * 0.5)
		_spawn_boundary_piece(parent, room_width - 1, z, colors[(z + 3) % colors.size()], PI * 0.5)


func _spawn_boundary_piece(parent: Node3D, x: int, z: int, color: String, y_rot: float = 0.0) -> void:
	var scene := _load_asset("%s/barrier_4x1x1_%s.gltf" % [color, color])
	if scene == null:
		return

	_spawn(parent, scene, _grid_position(x, z, wall_height), Vector3(0.0, y_rot, 0.0))


func _build_loop_markers(parent: Node3D) -> void:
	var arrow_assets := [
		"blue/platform_arrow_2x2x1_blue.gltf",
		"green/platform_arrow_2x2x1_green.gltf",
		"red/platform_arrow_2x2x1_red.gltf",
		"yellow/platform_arrow_2x2x1_yellow.gltf",
	]

	var marker_points := _loop_marker_points()
	for i in range(marker_points.size()):
		var scene := _load_asset(arrow_assets[i % arrow_assets.size()])
		if scene == null:
			continue

		var point: Vector4 = marker_points[i]
		_spawn(parent, scene, Vector3(point.x, 0.18, point.z), Vector3(0.0, point.w, 0.0))


func _loop_marker_points() -> Array[Vector4]:
	var points: Array[Vector4] = []
	var min_x := loop_margin_tiles
	var max_x := room_width - loop_margin_tiles - 1
	var min_z := loop_margin_tiles
	var max_z := room_depth - loop_margin_tiles - 1
	var step := 4

	for x in range(min_x, max_x + 1, step):
		points.append(Vector4(_grid_x(x), 0.0, _grid_z(min_z), 0.0))
	for z in range(min_z + step, max_z + 1, step):
		points.append(Vector4(_grid_x(max_x), 0.0, _grid_z(z), PI * 0.5))
	for x in range(max_x - step, min_x - 1, -step):
		points.append(Vector4(_grid_x(x), 0.0, _grid_z(max_z), PI))
	for z in range(max_z - step, min_z, -step):
		points.append(Vector4(_grid_x(min_x), 0.0, _grid_z(z), -PI * 0.5))

	return points


func _build_center_terrain(parent: Node3D) -> void:
	var center_x := int(room_width / 2)
	var center_z := int(room_depth / 2)
	var pieces := [
		"neutral/structure_A.gltf",
		"neutral/structure_B.gltf",
		"neutral/structure_C.gltf",
		"blue/platform_4x4x2_blue.gltf",
		"green/platform_slope_4x4x4_green.gltf",
		"red/platform_4x2x2_red.gltf",
		"yellow/arch_wide_yellow.gltf",
	]
	var positions := [
		Vector2i(center_x - 2, center_z - 2),
		Vector2i(center_x + 2, center_z - 1),
		Vector2i(center_x - 1, center_z + 2),
		Vector2i(center_x + 3, center_z + 3),
		Vector2i(center_x - 4, center_z + 3),
		Vector2i(center_x + 1, center_z - 4),
		Vector2i(center_x - 5, center_z - 4),
	]

	for i in range(positions.size()):
		var scene := _load_asset(pieces[i % pieces.size()])
		if scene == null:
			continue

		var cell: Vector2i = positions[i]
		if _is_on_loop_lane(cell.x, cell.y):
			continue

		var rot_y := float(i % 4) * PI * 0.5
		_spawn(parent, scene, _grid_position(cell.x, cell.y, 0.35), Vector3(0.0, rot_y, 0.0))


func _build_obstacles(parent: Node3D) -> void:
	var obstacle_assets := [
		"blue/cone_blue.gltf",
		"green/barrier_2x1x1_green.gltf",
		"red/bomb_A_red.gltf",
		"yellow/diamond_yellow.gltf",
		"blue/pipe_straight_A_blue.gltf",
		"green/railing_straight_single_green.gltf",
		"red/flag_B_red.gltf",
	]

	var placed := {}
	var tries := 0
	while placed.size() < obstacle_count and tries < obstacle_count * 12:
		tries += 1
		var cell := Vector2i(_rng.randi_range(2, room_width - 3), _rng.randi_range(2, room_depth - 3))
		var key := "%d,%d" % [cell.x, cell.y]
		if placed.has(key) or _is_on_loop_lane(cell.x, cell.y) or _is_near_center_terrain(cell):
			continue

		placed[key] = true
		var scene := _load_asset(obstacle_assets[placed.size() % obstacle_assets.size()])
		if scene == null:
			continue

		var rot_y := float(_rng.randi_range(0, 3)) * PI * 0.5
		_spawn(parent, scene, _grid_position(cell.x, cell.y, 0.2), Vector3(0.0, rot_y, 0.0))


func _build_landmarks(parent: Node3D) -> void:
	var center_x := int(room_width / 2)
	var center_z := int(room_depth / 2)
	var landmarks := [
		["neutral/signage_finish.gltf", Vector2i(room_width - 3, center_z), PI * 0.5],
		["green/flag_A_green.gltf", Vector2i(2, 2), 0.0],
		["red/button_base_red.gltf", Vector2i(center_x, 2), 0.0],
		["yellow/spring_pad_yellow.gltf", Vector2i(center_x, room_depth - 3), PI],
		["neutral/signage_arrows_right.gltf", Vector2i(2, center_z), -PI * 0.5],
	]

	for item in landmarks:
		var scene := _load_asset(item[0])
		if scene == null:
			continue

		var cell: Vector2i = item[1]
		var rot_y: float = item[2]
		_spawn(parent, scene, _grid_position(cell.x, cell.y, 0.25), Vector3(0.0, rot_y, 0.0))


func _build_lighting() -> void:
	if has_node("Sun"):
		return

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
	sun.light_energy = 2.0
	add_child(sun)


func _build_camera() -> void:
	if has_node("Camera3D"):
		return

	var span: float = float(max(room_width, room_depth)) * tile_spacing
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, span * 0.78, span * 0.95)
	camera.rotation_degrees = Vector3(-50.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)


func _load_asset(relative_path: String) -> PackedScene:
	var path := "%s/%s" % [PLATFORMER_ROOT, relative_path]
	var scene := load(path)
	if scene is PackedScene:
		return scene

	push_warning("Could not load Platformer asset: %s" % path)
	return null


func _spawn(parent: Node3D, scene: PackedScene, position: Vector3, rotation: Vector3) -> Node3D:
	var instance := scene.instantiate()
	if instance is Node3D:
		instance.position = position
		instance.rotation = rotation
		instance.add_to_group(GENERATED_GROUP)
		parent.add_child(instance)
		return instance

	instance.queue_free()
	return null


func _clear_generated() -> void:
	for node in get_tree().get_nodes_in_group(GENERATED_GROUP):
		if is_instance_valid(node):
			node.queue_free()


func _grid_x(x: int) -> float:
	return (x - (room_width - 1) * 0.5) * tile_spacing


func _grid_z(z: int) -> float:
	return (z - (room_depth - 1) * 0.5) * tile_spacing


func _grid_position(x: int, z: int, y: float) -> Vector3:
	return Vector3(_grid_x(x), y, _grid_z(z))


func _is_on_loop_lane(x: int, z: int) -> bool:
	var min_x := loop_margin_tiles
	var max_x := room_width - loop_margin_tiles - 1
	var min_z := loop_margin_tiles
	var max_z := room_depth - loop_margin_tiles - 1
	var on_horizontal: bool = x >= min_x and x <= max_x and (abs(z - min_z) < loop_width_tiles or abs(z - max_z) < loop_width_tiles)
	var on_vertical: bool = z >= min_z and z <= max_z and (abs(x - min_x) < loop_width_tiles or abs(x - max_x) < loop_width_tiles)
	return on_horizontal or on_vertical


func _is_near_center_terrain(cell: Vector2i) -> bool:
	var center := Vector2(room_width * 0.5, room_depth * 0.5)
	return Vector2(float(cell.x), float(cell.y)).distance_to(center) < 2.4
