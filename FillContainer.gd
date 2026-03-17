@tool
extends Control
class_name FillContainer


@export var h_fill = true:
	set(value):
		h_fill = value
		update_container()
@export var h_expand_margin = 0:
	set(value):
		h_expand_margin = value
		update_container()

@export var v_fill = true:
	set(value):
		v_fill = value
		update_container()
@export var v_expand_margin = 0:
	set(value):
		v_expand_margin = value
		update_container()

@export var invert_negative_space = false:
	set(value):
		invert_negative_space = value
		update_container()
@export var invert_children_negative_x = false:
	set(value):
		invert_children_negative_x = value
		update_container()
@export var invert_children_negative_y = false:
	set(value):
		invert_children_negative_y = value
		update_container()

@export var ignore_nodes: Array[Node]:
	set(value):
		ignore_nodes = value
		update_container()

@export var panel: StyleBox:
	set(value):
		panel = value
		update_container()


func _init():
	connect("draw", update_container)
	connect("child_entered_tree", on_child_entered_tree)
	connect("child_exiting_tree", on_child_exiting_tree)
	
	var Panel_instance = Panel.new()
	Panel_instance.name = "Panel"
	add_child(Panel_instance, false, Node.INTERNAL_MODE_FRONT)


func _ready():
	if not Engine.is_editor_hint():
		for child in get_children():
			child.connect("draw", update_container)
		
		update_container()


func update_container():
	var new_size = Vector2.ZERO
	var negative_size = Vector2.ZERO
	
	for child in get_children():
		if not ignore_nodes.has(child) and child.get("size"):
			var child_pos = child.position
			if child_pos.x < 0: negative_size.x += child_pos.x
			if child_pos.y < 0: negative_size.y += child_pos.y
			if invert_negative_space: child_pos += abs(child.position)
			
			if h_fill: new_size.x = max(new_size.x, child_pos.x + (child.size.x * child.scale.x))
			if v_fill: new_size.y = max(new_size.y, child_pos.y + (child.size.y * child.scale.y))
	
	new_size += Vector2(h_expand_margin, v_expand_margin)
	
	if h_fill:
		custom_minimum_size.x = new_size.x
		set_deferred("size/x", custom_minimum_size.x)
	
	if v_fill:
		custom_minimum_size.y = new_size.y
		set_deferred("size/y", custom_minimum_size.y)
	
	if is_instance_valid(panel):
		$Panel.add_theme_stylebox_override("panel", panel)
		$Panel.size = size
	else:
		$Panel.remove_theme_stylebox_override("panel")
	
	if negative_size != Vector2.ZERO:
		for node in get_children():
			if node is Node2D or node is Control:
				if invert_children_negative_x: node.position.x += abs(negative_size.x)
				if invert_children_negative_y: node.position.y += abs(negative_size.y)


func on_child_entered_tree(child):
	update_container()


func on_child_exiting_tree(child):
	update_container()
