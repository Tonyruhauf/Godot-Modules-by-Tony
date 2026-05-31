@tool
class_name _EditorInteractor extends Node


@export var disable_in_tree: bool = true ## Enable this if you don't want the inputs to trigger when clicking the node in the scene tree.

var parent: Control
var parent_is_editable = false
var parent_is_selected: bool = false
var lineEdit_previous_text: String

signal pressed


func _ready() -> void:
	InputMap.load_from_project_settings()


func _process(_delta: float) -> void:
	if parent: check_inputs()


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


func _get_configuration_warnings() -> PackedStringArray:
	var _parent = get_parent()
	if _parent && _parent is Control : return [] 
	return ["A parent of type Control is required"]


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			var _parent = get_parent()
			if !_parent || !(_parent is Control):
				parent = null
				update_configuration_warnings()
				return
			parent = _parent
			
			parent_is_editable = false
			if parent is LineEdit: parent_is_editable = true
			if parent is TextEdit: parent_is_editable = true
			
			if parent is LineEdit:
				lineEdit_previous_text = parent.text
		
		NOTIFICATION_UNPARENTED:
			if parent:
				parent = null
				parent_is_editable = false


func check_inputs() -> void:
	if Input.is_action_just_pressed("mouse_left_click"):
		if Input.is_key_pressed(KEY_ALT): return
		if !parent.is_visible_in_tree(): return
		
		if !parent.get_global_rect().has_point(parent.get_global_mouse_position()): return
		if !_is_mouse_in_viewport(): return
		
		on_just_pressed()


func _on_editor_selection_changed() -> void:
	if Input.is_key_pressed(KEY_ALT): return
	
	var selected_nodes: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	
	if parent in selected_nodes:
		if !disable_in_tree:
			on_just_pressed()
			
			EditorInterface.get_selection().clear()
			EditorInterface.edit_node(parent.owner)
		
	elif parent_is_selected:
		parent_is_selected = false
		_on_parent_unselected()


func _on_parent_unselected() -> void:
	if parent is LineEdit:
		if parent.text != lineEdit_previous_text:
			lineEdit_previous_text = parent.text
			parent.text_changed.emit(parent.text)


func on_just_pressed() -> void:
	pressed.emit()
	
	if parent is Button:
		parent.pressed.emit()
		return
	
	if parent_is_editable:
		EditorInterface.get_selection().clear()
		EditorInterface.edit_node(parent)
		parent_is_selected = true


func _is_mouse_in_viewport() -> bool:
	var vp_2d: SubViewport = EditorInterface.get_editor_viewport_2d()
	if not vp_2d: return false
	
	var vp_container: Control = vp_2d.get_parent()
	
	var is_vp_visible: bool = vp_container.is_visible_in_tree()
	if !is_vp_visible: return false
	
	# Get the global position of the mouse relative to the editor window
	var mouse_pos: Vector2 = vp_container.get_global_mouse_position()
	# Get the global bounding box of the viewport container
	var vp_rect: Rect2 = vp_container.get_global_rect()
	
	# Check if the mouse position falls within the rectangle
	var is_mouse_inside = vp_rect.has_point(mouse_pos)
	return is_mouse_inside
