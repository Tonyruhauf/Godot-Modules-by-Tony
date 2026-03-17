extends Sprite2D
class_name ClickableSprite


var touching_mouse = false
var is_mouse_held = false

signal clicked (clickable_sprite: ClickableSprite)
signal click_released (clickable_sprite: ClickableSprite)
signal click_outside_sprite (clickable_sprite: ClickableSprite)
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
		
		if event.is_action("mouse_left_click"):
			if is_instance_valid(texture.get_image()):
				if not texture.get_image().is_empty():
					if Input.is_action_just_released("mouse_left_click"):
						if touching_mouse and is_mouse_held:
							is_mouse_held = false
							click_released.emit(self)
					
					if is_pixel_opaque(get_local_mouse_position()):
						if Input.is_action_just_pressed("mouse_left_click"):
							get_viewport().set_input_as_handled()
							is_mouse_held = true
							clicked.emit(self)
					else:
						if Input.is_action_just_pressed("mouse_left_click"):
							click_outside_sprite.emit(self)
