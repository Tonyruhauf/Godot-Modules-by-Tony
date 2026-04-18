class_name LaserPointerRecording
extends Resource

@export_storage var frames_data: Dictionary[int, Array]


func record_property(laser_instance: Node2D, property_name: String):
	var frame: int = Engine.get_process_frames()
	var value = laser_instance.get(property_name)
	
	if value is Array:
		value = value.duplicate()
	
	var record = {property_name: value}
	
	if frames_data.has(frame):
		frames_data[frame].append(record)
	else:
		frames_data[frame] = [record]


func load_frame_data(laser_instance: Node2D, frame: int):
	var data: Array = get_frame_data(frame)
	for property: Dictionary in data:
		var p_name = property.keys().front()
		var p_value = property.values().front()
		laser_instance.set(p_name, p_value)


func get_frame_data(frame: int) -> Array:
	if frames_data.has(frame):
		return frames_data[frame]
	else:
		return []
