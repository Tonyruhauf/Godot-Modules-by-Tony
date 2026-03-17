extends HBoxContainer


var hours_last_valid_input = ""
var minutes_last_valid_input = ""


func _ready() -> void:
	$HoursInput.focus_exited.connect(_on_hours_input_text_submitted)
	$MinutesInput.focus_exited.connect(_on_minutes_input_text_submitted)


func get_hours() -> int:
	return int($HoursInput.text)


func get_minutes() -> int:
	return int($MinutesInput.text)


func parse_changed_text(new_text: String, last_valid_output_var_name: String, is_hours_input: bool) -> String:
	var is_valid = true
	
	if !new_text.is_valid_int() and !new_text.is_empty(): is_valid = false
	
	match is_hours_input:
		true: if int(new_text) > 24: is_valid = false
		false: if int(new_text) > 59: is_valid = false
	
	if is_valid:
		set(last_valid_output_var_name, new_text)
	else:
		new_text = get(last_valid_output_var_name)
	
	return new_text


func parse_submitted_text(new_text: String, current_text: String) -> String:
	if new_text.is_empty() and !current_text.is_empty():
		new_text = current_text
	
	if new_text.is_empty():
		new_text = "00"
	elif new_text.length() < 2:
		new_text = "0" + new_text
	
	return new_text


func _on_hours_input_text_changed(new_text: String) -> void:
	$HoursInput.text = parse_changed_text(new_text, "hours_last_valid_input", true)
	$HoursInput.caret_column = $HoursInput.text.length()


func _on_minutes_input_text_changed(new_text: String) -> void:
	$MinutesInput.text = parse_changed_text(new_text, "minutes_last_valid_input", false)
	$MinutesInput.caret_column = $MinutesInput.text.length()


func _on_hours_input_text_submitted(new_text: String = "") -> void:
	$HoursInput.text = parse_submitted_text(new_text, $HoursInput.text)


func _on_minutes_input_text_submitted(new_text: String = "") -> void:
	$MinutesInput.text = parse_submitted_text(new_text, $MinutesInput.text)


func _on_hours_input_editing_toggled(toggled_on: bool) -> void:
	if toggled_on: $HoursInput.text = ""


func _on_minutes_input_editing_toggled(toggled_on: bool) -> void:
	if toggled_on: $MinutesInput.text = ""
