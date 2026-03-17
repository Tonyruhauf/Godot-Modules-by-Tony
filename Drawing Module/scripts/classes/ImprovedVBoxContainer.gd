@tool
class_name ImprovedVBoxContainer
extends Control


@export var spacing: int = 4:
	set(value):
		spacing = value
		update_container()
@export var stylebox: StyleBox:
	set(value):
		if value == null:
			stylebox.changed.disconnect(queue_redraw)
			stylebox = value
		elif !value.changed.is_connected(queue_redraw):
			stylebox = value
			stylebox.changed.connect(queue_redraw)
		else:
			stylebox = value
		
		queue_redraw()


func _ready() -> void:
	child_entered_tree.connect(update_container)
	child_exiting_tree.connect(update_container)
	child_order_changed.connect(update_container)


func update_container(_arg = null):
	if is_inside_tree():
		await get_tree().process_frame
		var y_pos = 0
		
		for child in get_children():
			child.position.y = y_pos
			y_pos += (spacing + child.size.y)


func _draw() -> void:
	if is_instance_valid(stylebox):
		draw_style_box(stylebox, Rect2(Vector2.ZERO, size))
