class_name SaveDataResource
extends Resource


@export var saved_values: Dictionary


func set_value(key: String, value):
	saved_values[key] = value
