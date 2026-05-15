extends Node

@export var output_path := "res://screenshots/procedural_room_preview.png"
@export var output_size := Vector2i(1600, 1000)
@export var warmup_frames := 8


func _ready() -> void:
	get_window().size = output_size
	_capture_after_warmup()


func _capture_after_warmup() -> void:
	for _i in range(warmup_frames):
		await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
	var image: Image = get_viewport().get_texture().get_image()
	var error: Error = image.save_png(output_path)
	if error != OK:
		push_error("Could not save screenshot: %s" % output_path)
		get_tree().quit(1)
		return

	print("Saved screenshot: %s" % ProjectSettings.globalize_path(output_path))
	get_tree().quit()
