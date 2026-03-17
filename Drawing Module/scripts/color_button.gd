class_name ColorButton
extends Panel


@onready var stylebox: StyleBoxFlat = get_theme_stylebox("panel")

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		_on_color_changed()

signal pressed(button: ColorButton)


func _ready() -> void:
	_on_color_changed()


func _on_color_changed():
	if is_node_ready():
		stylebox.bg_color = color


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				pressed.emit(self)
