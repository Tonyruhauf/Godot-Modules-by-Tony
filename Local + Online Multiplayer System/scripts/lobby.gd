extends Panel


@onready var HostJoinMenu = owner
@onready var PlayerCard = preload("res://scenes/lobby_player_card.tscn")
@onready var PlayerCardsContainer = $PlayersCards

var min_players_required = 3:
	set(value):
		min_players_required = value
		_update_min_players_label()
var max_players = 0 # "0" means "infinite"
var players_count = 0:
	set(value):
		players_count = value
		_update_min_players_label()


func create_lobby():
	show()
	add_player(multiplayer.get_unique_id())


func _on_visibility_changed():
	if visible:
		$StartButton.visible = multiplayer.is_server()
		$MinPlayers.visible = multiplayer.is_server() and min_players_required != 0


func _update_min_players_label():
	$MinPlayers.text = "{0} / {1} players".format([players_count, min_players_required])


func clear():
	players_count = 0
	for player in PlayerCardsContainer.get_children():
		player.queue_free()


func add_player(peer_id):
	var player_card = PlayerCard.instantiate()
	player_card.name = str(peer_id)
	player_card.player_name = "Player_" + str(peer_id)
	
	PlayerCardsContainer.add_child(player_card)
	players_count += 1


func get_player(peer_id):
	return PlayerCardsContainer.get_node_or_null(str(peer_id))


@rpc("any_peer", "call_local")
func remove_player_from_lobby(peer_id):
	if multiplayer.is_server():
		var player_card = get_player(peer_id)
		if player_card:
			player_card.queue_free()
			players_count -= 1


func _on_leave_button_pressed() -> void:
	HostJoinMenu.leave_lobby(multiplayer.get_unique_id())


func _on_start_button_pressed() -> void:
	if _can_start_game():
		HostJoinMenu.rpc("start_game")


func is_full():
	return (players_count >= max_players) and max_players != 0


func _can_start_game():
	if !multiplayer.is_server(): return false
	
	if players_count < min_players_required:
		HostJoinMenu.show_error_to_user("Can't start lobby with less than %s players!" % min_players_required)
		return false
	
	return true
