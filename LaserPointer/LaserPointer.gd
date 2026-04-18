extends Node2D


@onready var recording: LaserPointerRecording = LaserPointerRecording.new()

@export var recording_mode: RecordingMode
@export var width: float = 3.0
@export var color: Color = Color.WHITE
@export var opacity: float = 0.6:
	set(value):
		opacity = value
		if recording_mode == RecordingMode.RECORD:
			recording.record_property(self, "opacity")
@export var trailing_lenght: int = 30:
	set(value):
		trailing_lenght = value
		if recording_mode == RecordingMode.RECORD:
			recording.record_property(self, "trailing_lenght")

var default_trailing_lenght: int
var fast_trailing_lenght: int

var default_opacity: float

var is_active: bool = false

var points_array: Array[Vector2]
var points_colors: Array[Color]

const RECORDING_SAVE_PATH = "res://laser_pointer_recording.tres"

enum RecordingMode {
	NONE,
	RECORD,
	PLAYBACK
}

## LASER CONTROLS
## Left click: laser on/off
## Right click: change laser trailing lenght (slow/fast)


func _ready() -> void:
	if recording_mode == RecordingMode.PLAYBACK:
		recording = load(RECORDING_SAVE_PATH)
	
	default_trailing_lenght = trailing_lenght
	fast_trailing_lenght = 7
	
	default_opacity = opacity
	
	tree_exiting.connect(_on_exiting_tree)


func _process(delta: float) -> void:
	if recording_mode == RecordingMode.PLAYBACK:
		_playback_process(delta)
		return
	
	recording.record_property(self, "points_array")
	recording.record_property(self, "points_colors")
	
	if is_active:
		add_new_point(get_local_mouse_position())
		
		for i in points_colors.size() - 1:
			points_colors[i].a -= delta
	else:
		remove_oldest_point()
		queue_redraw()


func _playback_process(_delta: float):
	recording.load_frame_data(self, Engine.get_process_frames())
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				1:
					if is_active: disable_laser()
					else: enable_laser()
				2:
					var tween = create_tween()
					if trailing_lenght == default_trailing_lenght:
						tween.tween_property(self, "trailing_lenght", fast_trailing_lenght, 1.0)
					else:
						tween.tween_property(self, "trailing_lenght", default_trailing_lenght, 1.0)


func disable_laser():
	var tween = create_tween()
	tween.tween_property(self, "opacity", 0.0, 1.0)
	
	await tween.finished
	is_active = false


func enable_laser():
	is_active = true
	
	var tween = create_tween()
	tween.tween_property(self, "opacity", default_opacity, 0.5)


func add_new_point(pos: Vector2):
	while points_array.size() >= trailing_lenght:
		remove_oldest_point()
	
	points_array.append(pos)
	
	var point_color = color
	point_color.a = opacity
	points_colors.append(point_color)
	
	queue_redraw()


func remove_oldest_point():
	if points_array.size() > 0:
		points_array.remove_at(0)
		points_colors.remove_at(0)


func _draw() -> void:
	if points_array.size() > 2:
		draw_polyline_colors(points_array.duplicate(), points_colors, width, true)


func _on_exiting_tree():
	if recording_mode == RecordingMode.RECORD:
		ResourceSaver.save(recording, RECORDING_SAVE_PATH)
		await get_tree().process_frame
