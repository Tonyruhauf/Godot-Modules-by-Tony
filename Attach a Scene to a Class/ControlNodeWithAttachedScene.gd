extends Control
class_name ControlNodeWithAttachedScene

var base_scene: Resource


func _ready():
	setup_scene()


func setup_scene():
	if not Engine.is_editor_hint() and scene_file_path.is_empty():
		var correct_pos = position
		var scene = base_scene.instantiate()
		
		var own_properties = []
		for p in get_script().get_script_property_list():
			own_properties.append(p.name)

		for property in scene.get_property_list():
			if not property.name in own_properties:
				set(property.name, scene.get(property.name))
		
		for child in scene.get_children():
			child.reparent(self)
			child.owner = null
			child.owner = self
		
		for connection in scene.get_incoming_connections():
			if not is_default_connection(scene, connection):
				connection.signal.disconnect(connection.callable)
				
				var callable = Callable(self, connection.callable.get_method())
				
				if connection.signal.get_object() == scene:
					connect(connection.signal.get_name(), callable, connection.flags)
				else:
					connection.signal.connect(callable, connection.flags)
		
		position = correct_pos
		scene.call_deferred("queue_free")


func is_default_connection(node, connection):
	# Instantiate a new node of the same type
	var new_node = node.duplicate(0)
	new_node.set_name("_temp_node")
	get_tree().root.add_child(new_node)
	
	# Get connections of the new node
	var node_default_connections = new_node.get_incoming_connections()
	
	# Compare connections
	for default_connection in node_default_connections:
		if str(default_connection) == str(connection):
			new_node.queue_free()
			return true
	
	new_node.queue_free()
	return false
