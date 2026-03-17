extends CharacterBody3D


@onready var camera = $Camera3D

const SPEED = 10.0
const JUMP_VELOCITY = 10.0

var gravity = ProjectSettings.get("physics/3d/default_gravity")


@rpc("authority", "call_local")
func RPC_set_multiplayer_authority(id: int, recursive: bool = true):
	set_multiplayer_authority(id, recursive)
	_on_multiplayer_authority_set()


func _on_multiplayer_authority_set():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true


func _unhandled_input(event):
	if not NetworkingManager.multiplayer.has_multiplayer_peer(): return
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		if not Input.is_action_pressed("mouse_right_click"):
			rotate_y(-event.relative.x * .005)
			camera.rotate_x(-event.relative.y * .005)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if Input.is_action_pressed("mouse_right_click"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.is_action_just_pressed("quit") and EngineDebugger.is_active():
		Toolbox.quit_tree()
		notification(NOTIFICATION_WM_CLOSE_REQUEST)
	
	if Input.is_action_just_pressed("mouse_left_click"):
		shoot.rpc() # This is just an example rpc function


func _physics_process(delta):
	if not NetworkingManager.multiplayer.has_multiplayer_peer(): return
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()


@rpc("call_local")
func shoot():
	pass


@rpc("any_peer", "call_local")
func set_value(property: String, value: Variant):
	set(property, value)


#
#@rpc("any_peer")
#func receive_damage():
	#health -= 1
	#if health <= 0:
		#health = 3
		#position = Vector3.ZERO
	#health_changed.emit(health)
#
#func _on_animation_player_animation_finished(anim_name):
	#if anim_name == "shoot":
		#anim_player.play("idle")
