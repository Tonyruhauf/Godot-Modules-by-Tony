@tool
extends VBoxContainer

@onready var color_button_scene := preload("res://modules/Drawing Module/scenes/color_button.tscn")

@export var colors: Array[ColorPalette]:
	set(value):
		var should_create_palette = true
		if !is_node_ready(): should_create_palette = false
		if !Engine.is_editor_hint(): should_create_palette = false
		if value.is_empty(): should_create_palette = false
		if value.size() <= colors.size(): should_create_palette = false
		
		if should_create_palette:
			value[-1] = ColorPalette.new()
			value[-1].colors = [Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK]
		
		colors = value

signal on_color_selected(color: Color)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	for palette in colors:
		add_palette(palette)


func add_palette(palette: ColorPalette):
	var container = HBoxContainer.new()
	container.name = palette.resource_path.get_slice("/", 5).replace(".tres", "")
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10)
	
	var i = 0
	for color in palette.colors:
		i += 1
		var color_button: ColorButton = color_button_scene.instantiate()
		color_button.color = color
		color_button.name = "color_%s" % i
		color_button.pressed.connect(_on_color_button_pressed)
		container.add_child(color_button)
	
	add_child(container)


func _on_color_button_pressed(button: ColorButton) -> void:
	on_color_selected.emit(button.color)
