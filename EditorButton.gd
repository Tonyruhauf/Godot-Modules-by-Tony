@tool
class_name CustEditorButton extends Node

@export var visual_mode: bool = true ## Fix a bug when the button is meant to be used visually on the scene.

var is_selected = false
var is_on_cooldown = false

signal editor_pressed


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		var editor_selection: EditorSelection = EditorInterface.get_selection()
		if not editor_selection.selection_changed.is_connected(_on_editor_selection_changed):
			editor_selection.selection_changed.connect(_on_editor_selection_changed)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		var editor_selection: EditorSelection = EditorInterface.get_selection()
		if editor_selection.selection_changed.is_connected(_on_editor_selection_changed):
			editor_selection.selection_changed.disconnect(_on_editor_selection_changed)


func _on_editor_selection_changed() -> void:
	if Input.is_key_pressed(KEY_ALT): return
	
	var selected_nodes: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	
	if self in selected_nodes:
		if is_selected and !visual_mode:
			is_selected = false
		else:
			is_selected = true
			on_button_pressed()
		
		EditorInterface.get_selection().clear()
		EditorInterface.edit_node(owner)


func on_button_pressed() -> void:
	emit_signal("editor_pressed")
