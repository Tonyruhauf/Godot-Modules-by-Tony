extends Node


@onready var Main: Node = get_tree().get_root().get_node("Main")


func translate_text(text: String) -> String:
	var regex := RegEx.new()
	regex.compile(r"\{(\w+)\}")  # Matches {KEY_NAME}
	var result := text
	for match in regex.search_all(text):
		var key := match.get_string(1)
		result = result.replace("{" + key + "}", tr(key))
	return result


func get_nested_value_in_dict(dict: Dictionary, path: String, separator: String = ".") -> Variant:
	var segments = path.split(separator)
	var current: Variant = dict

	var regex = RegEx.new()
	regex.compile("^([a-zA-Z0-9_]+)\\((.*)\\)$")  # matches method_name(args)

	for segment in segments:
		var result = regex.search(segment)
		if result:
			var method_name = result.get_string(1)
			var raw_args = result.get_string(2)
			var args = []

			if raw_args != "":
				# Basic argument splitting, handles strings and numbers
				var raw_arg_list = raw_args.split(",")
				for raw_arg in raw_arg_list:
					args.append(parse_argument(raw_arg.strip_edges()))

			if current != null and current.has_method(method_name):
				current = current.callv(method_name, args)
			else:
				return null
		else:
			# Not a function call; treat as key/property
			if typeof(current) == TYPE_DICTIONARY and current.has(segment):
				current = current[segment]
			elif typeof(current) == TYPE_OBJECT:
				current = current.get(segment)
			else:
				return null
	return current


func parse_argument(arg: String) -> Variant:
	# Try to convert string to a GDScript type
	if arg.begins_with("\"") and arg.ends_with("\""):
		return arg.substr(1, arg.length() - 2)
	elif arg.is_valid_float():
		return float(arg)
	elif arg.is_valid_int():
		return int(arg)
	elif arg == "true":
		return true
	elif arg == "false":
		return false
	else:
		return arg  # fallback, might be a string without quotes


func area_overlaps_area_named(area_A: Area2D, area_B_name: String):
	for area in area_A.get_overlapping_areas():
		if area.name == area_B_name:
			return area
	return false
