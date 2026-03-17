extends Node


@onready var Player = preload("res://scenes/player.tscn")

var players_list = {}


func _ready() -> void:
	if NetworkingManager.is_hosting_server():
		add_player(NetworkingManager.multiplayer.get_unique_id())
	
		await get_tree().create_timer(0.5).timeout
		
		for peer_id in NetworkingManager.multiplayer.get_peers():
			add_player(peer_id)
	
	NetworkingManager.disconnected_from_server.connect(_on_disconnected_from_server)


func _on_disconnected_from_server():
	queue_free()


func add_player(peer_id):
	var player = Player.instantiate()
	players_list[peer_id] = player
	add_child(player, true)
	
	await get_tree().process_frame
	player.rpc("RPC_set_multiplayer_authority", peer_id)


func remove_player(peer_id):
	var player = players_list[peer_id]
	if player:
		players_list.erase(peer_id)
		player.queue_free()
