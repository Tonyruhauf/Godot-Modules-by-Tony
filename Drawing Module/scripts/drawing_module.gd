extends Node2D


@onready var drawing_area = $CanvasLayer/DrawArea
@onready var drawing_area_buttons_container = $CanvasLayer/DrawArea/DrawAreaButtonsContainer
@onready var undo_button: Button = drawing_area_buttons_container.get_node("UndoButton")
@onready var redo_button: Button = drawing_area_buttons_container.get_node("RedoButton")
@onready var tools_buttons_container = $CanvasLayer/ToolsPanel/ImprovedVBoxContainer/BrushesContainer
@onready var premade_colors = $CanvasLayer/ToolsPanel/ImprovedVBoxContainer/PremadeColorsScrollContainer/PremadeColors
@onready var color_picker = $CanvasLayer/ToolsPanel/ImprovedVBoxContainer/ColorPickerBrush
@onready var brush_size_spinbox = $CanvasLayer/ToolsPanel/ImprovedVBoxContainer/BrushSize/Control/SpinBox
@onready var layers_items_container = $CanvasLayer/LayersItemsContainer
@onready var add_layer_button = layers_items_container.get_node("AddLayerButton")
@onready var save_button = $CanvasLayer/ToolsPanel/ButtonSave

@onready var layer_item_scene = preload("res://modules/Drawing Module/scenes/layer_item.tscn")

@onready var tools_buttons: Dictionary[String, Button] = {
	"fill": tools_buttons_container.get_node("ButtonToolFill"),
	"square": tools_buttons_container.get_node("ButtonToolSquare"),
	"circle": tools_buttons_container.get_node("ButtonToolCircle"),
	"eraser": tools_buttons_container.get_node("ButtonToolEraser"),
}

@export var canva_size := Vector2(800, 800)
@export var bg_color := Color(0.902, 0.902, 0.902)
@export var tool_selected: DrawTool = DrawTool.CIRCLE
@export var brush_size := 10.0
@export var brush_color := Color.BLACK

var layers: Array[Layer]
var active_layer: Layer:
	set(value):
		active_layer = value
		strokes_list = active_layer.content["lines"]
		fill_polygons = active_layer.content["fill"]
var strokes_list: Array[Dictionary] # Synced to the active_layer "content.lines" property.
var strokes_points_references: Dictionary[Vector2, Array]
var fill_polygons: Array[Dictionary] # Synced to the active_layer "content.fill" property.
var actions_history: Array[Dictionary]
var undone_actions_history: Array[Dictionary]
var last_mouse_pos: Vector2
var pen_exited_canva := false

const IMAGE_SAVE_PATH = "res://Saved Drawings/images"

enum DrawTool {
	FILL,
	CIRCLE,
	SQUARE,
	ERASER
}

enum ActionType {
	DRAW,
	FILL,
	CLEAR
}


func _ready() -> void:
	drawing_area.custom_minimum_size = canva_size
	drawing_area.color = bg_color
	
	layers_items_container.set_meta("default_size", layers_items_container.size)
	add_layer_button.pressed.connect(_add_new_layer)
	
	for key in ["normal", "pressed", "hover"]:
		var new_color = (bg_color if key == "normal" else bg_color.darkened(0.0))
		var stylebox = undo_button.get_theme_stylebox(key)
		stylebox.bg_color = new_color
		undo_button.add_theme_stylebox_override(key, stylebox)
		stylebox= redo_button.get_theme_stylebox(key)
		stylebox.bg_color = new_color
		redo_button.add_theme_stylebox_override(key, stylebox)
	
	undo_button.pressed.connect(undo)
	redo_button.pressed.connect(redo)
	
	for key in tools_buttons:
		var button = tools_buttons[key]
		button.pressed.connect(on_tool_button_pressed.bind(key))
	
	tools_buttons.fill.pressed.connect(set_tool.bind(DrawTool.FILL))
	tools_buttons.square.pressed.connect(set_tool.bind(DrawTool.SQUARE))
	tools_buttons.circle.pressed.connect(set_tool.bind(DrawTool.CIRCLE))
	tools_buttons.eraser.pressed.connect(set_tool.bind(DrawTool.ERASER))
	
	premade_colors.on_color_selected.connect(set_brush_color)
	color_picker.color_changed.connect(set_brush_color)
	brush_size_spinbox.value_changed.connect(set_brush_size)
	
	save_button.pressed.connect(save_drawing_to_file.bind(IMAGE_SAVE_PATH))
	
	_add_new_layer()
	layers_items_container.get_child(0).select_sub_layer(Layer.SubLayer.LINES)


func _process(_delta: float) -> void:
	queue_redraw()
	if Input.is_action_just_pressed("use_pen"): _on_pen_down()
	if Input.is_action_pressed("use_pen"): _pen_down_process()
	if Input.is_action_just_released("use_pen"): _on_pen_up()


func set_brush_color(color: Color):
	brush_color = color
	color_picker.color = color


func set_brush_size(value: float) -> void:
	brush_size = value


func set_tool(tool: DrawTool):
	tool_selected = tool


func undo():
	if actions_history.is_empty(): return
	var action = actions_history.back()
	
	match action.type:
		ActionType.DRAW:
			action.sub_layer.erase(action.data)
			_remove_points_references(action.data.points)
		
		ActionType.FILL:
			action.sub_layer.erase(action.data)
	
	queue_redraw()
	undone_actions_history.append(actions_history.pop_back())


func redo():
	if undone_actions_history.is_empty(): return
	var action = undone_actions_history.back()
	
	match action.type:
		ActionType.DRAW:
			action.sub_layer.append(action.data)
			for p in action.data.points: _reference_stroke_point(p)
		
		ActionType.FILL:
			action.sub_layer.append(action.data)
	
	queue_redraw()
	actions_history.append(undone_actions_history.pop_back())


func _register_action(type: ActionType, data: Dictionary, sub_layer_array: Array):
	actions_history.append({
		"layer": active_layer,
		"sub_layer": sub_layer_array,
		"type": type,
		"data": data
	})


func _pen_down_process():
	if last_mouse_pos == get_global_mouse_position(): return
	else: last_mouse_pos = get_global_mouse_position()
	
	if tool_selected == DrawTool.FILL:
		if is_mouse_in_drawing_area():
			var pos = _get_closest_stroke_point_to_pos(get_global_mouse_position())
			if pos != null: add_fill_point(pos)
	else:
		if !is_mouse_in_drawing_area():
			pen_exited_canva = true
			return
		elif pen_exited_canva:
			pen_exited_canva = false
			add_stroke()
		
		add_point(get_global_mouse_position())


func _on_pen_down():
	if is_mouse_in_drawing_area():
		if tool_selected == DrawTool.FILL:
			add_fill_polygon()
		else:
			add_stroke()


func _on_pen_up():
	pen_exited_canva = false
	
	if !strokes_list.is_empty():
		if strokes_list.back().points.is_empty():
			strokes_list.pop_back()


func is_mouse_in_drawing_area() -> bool:
	var area_rect: Rect2 = %DrawArea.get_rect()
	return area_rect.has_point(get_global_mouse_position())


func add_stroke(custom_width: float = -1.0, custom_color: Color = Color(1,1,1,0)):
	if tool_selected == DrawTool.ERASER: custom_color = bg_color
	
	var new_stroke = {}
	new_stroke.points = []
	new_stroke.tool = tool_selected
	new_stroke.width = (brush_size if custom_width == -1.0 else custom_width)
	new_stroke.color = (brush_color if custom_color == Color(1,1,1,0) else custom_color)
	
	active_layer.get_active_sub_layer().append(new_stroke)
	
	_register_action(ActionType.DRAW, new_stroke, active_layer.get_active_sub_layer())


func add_point(pos: Vector2):
	var sub_layer_lines = active_layer.get_active_sub_layer()
	var stroke_points = sub_layer_lines.back().points
	stroke_points.append(pos)
	
	_reference_stroke_point(pos)
	
	queue_redraw()


func add_fill_polygon():
	var polygon_data = {}
	polygon_data.points = []
	polygon_data.color = brush_color
	polygon_data.tool = tool_selected
	fill_polygons.append(polygon_data)
	_register_action(ActionType.FILL, polygon_data, active_layer.content["fill"])


func add_fill_point(pos: Vector2):
	if !fill_polygons.is_empty():
		var points: Array = fill_polygons.back().points
		if _is_polygon_point_valid(pos, points): points.append(pos)
		queue_redraw()


func _is_polygon_point_valid(point: Vector2, polygon: PackedVector2Array):
	if polygon.size() < 3: return true
	
	var new_polygon = polygon.duplicate()
	new_polygon.append(point)
	
	return !Geometry2D.triangulate_polygon(new_polygon).is_empty()


func _reference_stroke_point(pos: Vector2):
	var reference_point = get_reference_point_from_pos(pos)
	if strokes_points_references.has(reference_point):
		strokes_points_references[reference_point].append(pos)
	else:
		strokes_points_references[reference_point] = [pos]


func _remove_points_references(points: PackedVector2Array):
	for p in points:
		var reference_point = get_reference_point_from_pos(p)
		strokes_points_references[reference_point].erase(p)


func _get_closest_stroke_point_to_pos(pos: Vector2):
	var reference_point = get_reference_point_from_pos(pos)
	var closest_point_dist := 9999999.0
	var closest_point = null
	
	if strokes_points_references.has(reference_point):
		for p: Vector2 in strokes_points_references[reference_point]:
			var p_dist = p.distance_squared_to(pos)
			if p_dist < closest_point_dist:
				closest_point = p
				closest_point_dist = p_dist
	
	return closest_point


func _draw():
	var layers_sorted = layers.duplicate()
	layers_sorted.sort_custom(func(a,b): return a.draw_order > b.draw_order)
	
	for layer in layers_sorted:
		var layer_strokes = layer.content["lines"]
		var layer_fill = layer.content["fill"]
		
		for data in layer_fill:
			match data.tool:
				DrawTool.FILL:
					if Geometry2D.triangulate_polygon(data.points).is_empty(): continue
					draw_colored_polygon(data.points, data.color)
				_:
					_draw_stroke(data)
		
		for stroke in layer_strokes:
			_draw_stroke(stroke)
	
	_draw_brush_point()


func _draw_stroke(stroke: Dictionary):
	var stroke_points = stroke.points
	if stroke_points.is_empty(): return
	if stroke_points.size() < 2:
		if stroke.tool == DrawTool.SQUARE:
			var size := Vector2(stroke.width, stroke.width)
			var pos: Vector2 = stroke_points.front() - (size / 2)
			var rect = Rect2(pos, size)
			draw_rect(rect, stroke.color, true, -1.0, true)
		else:
			draw_circle(stroke_points.front(), stroke.width / 2, stroke.color, true, -1.0, true)
	else:
		if [DrawTool.SQUARE, DrawTool.ERASER].has(stroke.tool):
			draw_polyline(stroke_points, stroke.color, stroke.width, true)
		else:
			var smoothed_points = bezier_smooth(stroke_points, 1.0, 32)
			draw_polyline(smoothed_points, stroke.color, stroke.width, true)
			draw_circle(smoothed_points.front(), stroke.width / 2, stroke.color, true, -1.0, true)
			draw_circle(smoothed_points.back(), stroke.width / 2, stroke.color, true, -1.0, true)


func _draw_brush_point():
	draw_circle(get_global_mouse_position(), brush_size / 2, brush_color, true, -1, true)


func bezier_smooth(points: Array, smoothness: float, samples_per_segment := 16) -> Array:
	# Requires at least two points
	if points.size() < 2:
		return points.duplicate()
	
	var out_points := []
	var count := points.size()
	
	for i in range(count - 1):
		var p0 = points[max(i - 1, 0)]
		var p1 = points[i]
		var p2 = points[i + 1]
		var p3 = points[min(i + 2, count - 1)]
		
		# Catmull-Rom to cubic Bézier conversion
		var c1 = p1 + (p2 - p0) * (smoothness / 6.0)
		var c2 = p2 - (p3 - p1) * (smoothness / 6.0)
		
		# Sample the cubic Bézier curve
		for s in range(samples_per_segment):
			var t = float(s) / float(samples_per_segment)
			var mt = 1.0 - t
			
			# Cubic Bézier interpolation
			var point = mt * mt * mt * p1 +\
				3.0 * mt * mt * t * c1 +\
				3.0 * mt * t * t * c2 +\
				t * t * t * p2
			
			out_points.append(point)
	
	# Add the final input point
	out_points.append(points[count - 1])
	return out_points


func get_reference_point_from_pos(pos: Vector2):
	var grid_size = 50
	return round(pos / grid_size) * grid_size


func on_tool_button_pressed(button_key: String):
	for key in tools_buttons:
		var button = tools_buttons[key]
		if key != button_key: button.button_pressed = false


func _on_button_clear_pressed() -> void:
	strokes_list.clear()
	queue_redraw()


func _add_new_layer() -> void:
	var new_layer = Layer.new()
	
	layers.append(new_layer)
	
	_add_new_layer_item(new_layer)


func _add_new_layer_item(layer: Layer) -> void:
	var layer_item = layer_item_scene.instantiate()
	var container_child_count = layers_items_container.get_child_count() + 1
	var layers_count = container_child_count - 1
	
	layer.draw_order = layers_count - 1
	layer.name = "Layer %s" % layers_count
	
	layer_item.layer = layer
	layer_item.draw_order_changed.connect(_on_layer_item_draw_order_changed)
	layer_item.sub_layer_selected.connect(_on_layer_selected)
	
	layers_items_container.add_child(layer_item)
	layers_items_container.move_child(add_layer_button, container_child_count)
	
	if layers_count <= 2:
		layers_items_container.size.y = layers_items_container.get_meta("default_size").y
	else:
		layers_items_container.size.y += layer_item.size.y


func _on_layer_item_draw_order_changed(layer_item: Control):
	layers_items_container.move_child(layer_item, layer_item.layer.draw_order)
	queue_redraw()


func _on_layer_selected(layer_item: Control):
	active_layer = layer_item.layer
	queue_redraw()


func save_drawing_to_texture() -> ImageTexture:
	var image: Image = await save_drawing_to_image()
	return ImageTexture.create_from_image(image)


func save_drawing_to_image() -> Image:
	await RenderingServer.frame_post_draw
	
	# Get the viewport image.
	var img = get_viewport().get_texture().get_image()
	
	# Crop the image so we only have canvas area.
	var cropped_image = img.get_region(Rect2(drawing_area.position, drawing_area.size))
	
	return cropped_image


func save_drawing_to_file(dir_path: String) -> void:
	var image = await save_drawing_to_image()
	
	var file_path = dir_path + "/drawing_%s.png"
	var next_ID: int = 0
	for file in DirAccess.open(dir_path).get_files():
		var file_ID_string = file[file.find("_") + 1]
		next_ID = int(file_ID_string) + 1
	
	file_path = file_path % str(next_ID)
	image.save_png(file_path)
