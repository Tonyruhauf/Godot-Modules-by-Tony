extends Panel


@onready var name_label = $VBoxContainer/NameLabel
@onready var move_up_button = $MoveUpButton
@onready var move_down_button = $MoveDownButton
@onready var lines_layer_button = $VBoxContainer/HBoxContainer/LinesLayerButton
@onready var fill_layer_button = $VBoxContainer/HBoxContainer/FillLayerButton

var layer: Layer

signal draw_order_changed(layer_item)
signal sub_layer_selected(sub_layer: String)


func _ready() -> void:
	add_to_group("LayerItems")
	name_label.text = layer.name
	
	move_up_button.pressed.connect(change_layer_draw_order.bind(-1))
	move_down_button.pressed.connect(change_layer_draw_order.bind(1))
	
	lines_layer_button.pressed.connect(select_sub_layer.bind(Layer.SubLayer.LINES))
	fill_layer_button.pressed.connect(select_sub_layer.bind(Layer.SubLayer.FILL))


func change_layer_draw_order(amount: int, forced: bool = false):
	if !forced:
		if get_index() == 0 and amount < 0: return
		if get_index() == (get_parent().get_child_count() - 2) and amount > 0: return
	
	if !forced: _update_other_layers_draw_order(amount)
	
	layer.draw_order += amount
	draw_order_changed.emit(self)


func _update_other_layers_draw_order(value_change: int):
	var layers_above = get_layers_above()
	var layers_below = get_layers_below()
	
	if !layers_above.is_empty() and value_change == -1:
		layers_above.back().change_layer_draw_order(1, true)
	
	if !layers_below.is_empty() and value_change == 1:
		layers_below.back().change_layer_draw_order(-1, true)


func get_layers_above():
	var layers_above = []
	for child in get_parent().get_children():
		if child is Button: continue
		if child.layer.draw_order < layer.draw_order:
			layers_above.append(child)
	layers_above.sort_custom(func(a,b): return a.layer.draw_order < b.layer.draw_order)
	return layers_above


func get_layers_below():
	var layers_below = []
	for child in get_parent().get_children():
		if child is Button: continue
		if child.layer.draw_order > layer.draw_order:
			layers_below.append(child)
	layers_below.sort_custom(func(a,b): return a.layer.draw_order > b.layer.draw_order)
	return layers_below


func select_sub_layer(sub_layer: Layer.SubLayer):
	get_tree().call_group("LayerItems", "unselect_sub_layers_buttons", self)
	
	match sub_layer:
		Layer.SubLayer.LINES:
			layer.selected_sub_layer = "lines"
			lines_layer_button.disabled = true
			fill_layer_button.button_pressed = false
			fill_layer_button.disabled = false
		
		Layer.SubLayer.FILL:
			layer.selected_sub_layer = "fill"
			fill_layer_button.disabled = true
			lines_layer_button.button_pressed = false
			lines_layer_button.disabled = false
	
	sub_layer_selected.emit(self)


func unselect_sub_layers_buttons(call_origin: Control):
	if self == call_origin: return
	
	for button in [lines_layer_button, fill_layer_button]:
		button.button_pressed = false
		button.disabled = false
