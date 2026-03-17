@tool
class_name CustomAudioStreamPlayer
extends AudioStreamPlayer

@export_group("Variation System")
@export var db_range := Vector2(0.0, 0.0):
	set(value):
		if value.y >= value.x:
			db_range = value
@export var pitch_range := Vector2(1.0, 1.0):
	set(value):
		if value.y >= value.x:
			pitch_range.y = value.y
			pitch_range.x = max(0.01, value.x)


func _ready() -> void:
	if Engine.is_editor_hint() and OS.has_feature("pc"):
		pass
		#if !EditorInterface.get_inspector().property_edited.is_connected(on_property_changed):
			#EditorInterface.get_inspector().property_edited.connect(on_property_changed)
	else:
		finished.connect(on_property_changed.bind("playing"))


func on_property_changed(property_name: String) -> void:
	if property_name == "playing":
		if db_range != Vector2.ZERO: volume_db = randf_range(db_range.x, db_range.y)
		if pitch_range != Vector2(1.0, 1.0): pitch_scale = randf_range(pitch_range.x, pitch_range.y)
