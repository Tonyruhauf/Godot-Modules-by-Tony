class_name TimeValue
extends Resource

@export_range(0, 24, 1.0) var hours: int:
	set(value):
		hours = value
		changed.emit()
@export_range(0, 59, 1.0) var minutes: int:
	set(value):
		minutes = value
		changed.emit()


func _init(_hours: int = 0, _minutes: int = 0) -> void:
	set_time(_hours, _minutes)


func set_time(_hours: int = 0, _minutes: int = 0):
	hours = _hours
	minutes = _minutes
	
	_convert_to_valid_time()


func _convert_to_valid_time():
	for i in (minutes / 60) + 1:
		if minutes > 59:
			minutes -= 60
			hours += 1


func is_equal_to(b: TimeValue):
	if !is_instance_valid(b): b = TimeValue.new()
	return (hours == b.hours and minutes == b.minutes)


func is_less_than(b: TimeValue, allow_equal: bool = false):
	if !is_instance_valid(b): b = TimeValue.new()
	if allow_equal and hours == b.hours and minutes == b.minutes: return true
	return get_min_time(self, b) == self


func is_more_than(b: TimeValue, allow_equal: bool = false):
	if !is_instance_valid(b): b = TimeValue.new()
	if allow_equal and hours == b.hours and minutes == b.minutes: return true
	return get_max_time(self, b) == self


static func get_min_time(a: TimeValue, b: TimeValue):
	if !is_instance_valid(a): a = TimeValue.new(9999, 9999)
	if !is_instance_valid(b): b = TimeValue.new(9999, 9999)
	
	if a.hours < b.hours:
		return a
	elif a.hours == b.hours and a.minutes < b.minutes:
		return a
	
	if b.hours < a.hours:
		return b
	elif b.hours == a.hours and b.minutes < a.minutes:
		return b
	
	return null


static func get_max_time(a: TimeValue, b: TimeValue):
	if !is_instance_valid(a): a = TimeValue.new()
	if !is_instance_valid(b): b = TimeValue.new()
	
	if a.hours > b.hours:
		return a
	elif a.hours == b.hours and a.minutes > b.minutes:
		return a
	
	if b.hours > a.hours:
		return b
	elif b.hours == a.hours and b.minutes > a.minutes:
		return b
	
	return null


func get_as_string():
	var hours_string = str(hours)
	var minutes_string = str(minutes)
	if hours < 10: hours_string = "0" + hours_string
	if minutes < 10: minutes_string = "0" + minutes_string
	return hours_string + ":" + minutes_string


func get_as_hours() -> float:
	return float(get_as_minutes()) / 60.0


func get_as_minutes() -> int:
	var time_in_minutes = minutes
	time_in_minutes += hours * 60
	return time_in_minutes


func add_time(time_value: TimeValue, valid_day_time: bool = false):
	hours += time_value.hours
	minutes += time_value.minutes
	
	_convert_to_valid_time()
	
	if valid_day_time:
		hours = min(24, hours)


func reduce_time(time_value: TimeValue, valid_day_time: bool = false):
	#print("\n\nReduce")
	#print(str(hours) + ":" + str(minutes))
	#print("-")
	#print(str(time_value.hours) + ":" + str(time_value.minutes))
	hours -= time_value.hours
	minutes -= time_value.minutes
	
	#print("=")
	#print(str(hours) + ":" + str(minutes))
	
	while minutes < 0:
		if hours <= 0: break
		hours -= 1
		minutes += 60
	
	if valid_day_time:
		minutes = max(0, minutes)
		hours = max(0, hours)
	
	#print("===")
	#print(str(hours) + ":" + str(minutes))
