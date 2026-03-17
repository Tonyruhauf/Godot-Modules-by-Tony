extends Node2DWithAttachedScene
class_name ExampleClass


@export var value: String = "":
	set(value):
		if has_node("ValueLabel"): $ValueLabel.text = value


func _init() -> void:
	base_scene = load("res://scenes/example_scene.tscn")