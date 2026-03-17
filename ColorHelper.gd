extends Node


func get_monochromatic_color(base_color: Color, factor: float) -> Color:
	factor = clamp(factor, 0.0, 1.0)
	
	var hsv = {"h": base_color.h, "s": base_color.s, "v": base_color.v}
	
	# Adjust the saturation and value to create a monochromatic effect
	var new_saturation = hsv.s * factor
	var new_value = hsv.v * factor
	
	return Color.from_hsv(hsv.h, new_saturation, new_value, base_color.a)


func generate_random_pleasing_color():
	var golden_ratio_conjugate = 0.618033988749895
	var hue = randf() # Random initial hue value
	hue += golden_ratio_conjugate
	#hue = fmod(hue, 1.0) # Ensure the hue stays within the range [0, 1]
	
	var saturation = 0.4 + randf() * 0.6 # Random saturation value between 0.4 and 1.0
	var lightness = 0.4 + randf() * 0.2 # Random lightness value between 0.4 and 0.6
	
	return Color.from_ok_hsl(hue, saturation, lightness)


func convert_hsv_to_readable_values(h: float, s: float, v: float) -> Dictionary:
	var normalized_h = int(h * 359.0)
	var normalized_s = int(s * 100.0)
	var normalized_v = int(v * 100.0)
	return {"h": normalized_h, "s": normalized_s, "v": normalized_v}


func convert_hsv_to_raw(h: int, s: int, v: int) -> Color:
	var normalized_h = float(h) / 359.0
	var normalized_s = float(s) / 100.0
	var normalized_v = float(v) / 100.0
	
	var color = Color.from_hsv(normalized_h, normalized_s, normalized_v)
	return color
