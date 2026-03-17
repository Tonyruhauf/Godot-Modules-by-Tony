extends Sprite2D
class_name ClickableSprite


var touching_mouse = false
var is_mouse_right_click_held = false
var is_mouse_left_click_held = false

signal clicked (event: InputEventMouseButton, clickable_sprite: ClickableSprite)
signal click_released (event: InputEventMouseButton, clickable_sprite: ClickableSprite)
signal click_outside_sprite (event: InputEventMouseButton, clickable_sprite: ClickableSprite)
signal mouse_entered
signal mouse_exited


func _unhandled_input(event):
	if is_visible_in_tree() and is_instance_valid(texture):
		if not touching_mouse:
			if is_pixel_opaque(get_local_mouse_position()):
				mouse_entered.emit()
				touching_mouse = true
		elif not is_pixel_opaque(get_local_mouse_position()):
			mouse_exited.emit()
			touching_mouse = false
		
		if event is InputEventMouseButton:
			if is_instance_valid(texture.get_image()):
				if not texture.get_image().is_empty():
					if !event.pressed:
						if touching_mouse and (is_mouse_right_click_held or is_mouse_left_click_held):
							if event.button_index == 1: is_mouse_right_click_held = false
							elif event.button_index == 2: is_mouse_left_click_held = false
							click_released.emit(event, self)
					
					if is_pixel_opaque(get_local_mouse_position()):
						if event.pressed:
							get_viewport().set_input_as_handled()
							if event.button_index == 1: is_mouse_right_click_held = true
							elif event.button_index == 2: is_mouse_left_click_held = true
							clicked.emit(event, self)
					else:
						if event.pressed:
							click_outside_sprite.emit(event, self)
