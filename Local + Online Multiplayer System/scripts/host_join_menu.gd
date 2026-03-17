extends CanvasLayer


@onready var HostJoinPanel = $HostJoinPanel
@onready var HostPanel = $HostPanel
@onready var JoinPanel = $JoinPanel

@onready var HostOnlineButton = $HostPanel/MarginContainer/VBoxContainer/HostOnlineButton
@onready var HostLocalButton = $HostPanel/MarginContainer/VBoxContainer/HostLocalButton

@onready var JoinOnlineButton = $JoinPanel/MarginContainer/TabContainer/Online/JoinButton
@onready var JoinLocalButton = $JoinPanel/MarginContainer/TabContainer/Local/JoinButton

@onready var ServerAdressLineEdit = $JoinPanel/MarginContainer/TabContainer/Online/ServerAdressLineEdit
@onready var LoadingMessage = $LoadingMessage
@onready var LoadingMessage_Label = $LoadingMessage/MarginContainer/VBoxContainer/Label
@onready var Lobby = $Lobby
@onready var LobbyAdressLabel = $Lobby/ServerAdress
@onready var ErrorPanel = $ErrorPanel
@onready var ErrorPanel_Label = $ErrorPanel/MarginContainer/VBoxContainer/Label

@onready var game_scene_packed = preload("res://scenes/game_scene.tscn")

var game_scene: Node
var last_opened_menu: Node


func _ready() -> void:
	last_opened_menu = HostJoinPanel
	
	HostOnlineButton.pressed.connect(start_hosting.bind(false))
	HostLocalButton.pressed.connect(start_hosting.bind(true))
	
	JoinOnlineButton.pressed.connect(join.bind(false))
	JoinLocalButton.pressed.connect(join.bind(true))
	
	NetworkingManager.peer_connected.connect(_on_peer_connected)
	NetworkingManager.peer_disconnected.connect(_on_peer_disconnected)
	NetworkingManager.server_started.connect(_on_server_started)
	NetworkingManager.disconnected_from_server.connect(_on_disconnected_from_server)
	NetworkingManager.upnp_setup_failed.connect(_on_upnp_setup_failed)


func _on_host_button_pressed():
	last_opened_menu = HostPanel
	HostJoinPanel.hide()
	HostPanel.show()


func _on_join_button_pressed():
	last_opened_menu = JoinPanel
	HostJoinPanel.hide()
	JoinPanel.show()


func _on_back_button_pressed():
	last_opened_menu = HostJoinPanel
	HostPanel.hide()
	JoinPanel.hide()
	HostJoinPanel.show()


func start_hosting(local: bool):
	hide_menu()
	NetworkingManager.create_server(local)


func join(local: bool):
	var encoded_adress = ServerAdressLineEdit.text
	if local:
		var ip = ClientDiscovery.discovered_host
		if ip == "":
			show_error_to_user("Aucun hôte détecté")
			return
		encoded_adress = NetworkingManager.encode_adress(ip)
	
	show_loading_message("Connexion au lobby...")
	await get_tree().create_timer(0.5).timeout
	LoadingMessage.hide()
	
	var result = NetworkingManager.join_server(encoded_adress)
	if result == OK:
		hide_menu()
		Lobby.show()
	else:
		show_error_to_user(
			"Adresse incorrecte"
		)


func _on_server_started():
	Lobby.create_lobby()


@rpc("any_peer", "call_local")
func leave_lobby(peer_id = null):
	if peer_id != null and multiplayer.get_unique_id() != peer_id: return
	
	if NetworkingManager.is_hosting_server():
		NetworkingManager.close_server()
	
	elif NetworkingManager.is_server_running():
		Lobby.rpc("remove_player_from_lobby", peer_id)
		NetworkingManager.disconnect_from_server()
	
	Lobby.clear()
	show_menu()


func hide_menu():
	last_opened_menu.hide()


func show_menu():
	process_mode = Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	Lobby.hide()
	
	last_opened_menu.show()
	show()


@rpc("call_local")
func start_game():
	on_game_started()
	
	# Delaying the server to make sure the scene is ready for all clients first.
	if NetworkingManager.is_hosting_server():
		show_loading_message("Lancement de la session...")
		await get_tree().create_timer(2).timeout
		LoadingMessage.hide()
	
	var transition_params = SceneTransitionParams.new()
	transition_params.first_scene_action = transition_params.FirstSceneAction.HIDE
	game_scene = await SceneTransitioner.transition_to_scene(self, game_scene_packed, transition_params)


func on_game_started():
	Lobby.hide()


func _on_upnp_setup_failed():
	show_menu()
	show_error_to_user(
			"Impossible de créer un Lobby:
			Réseau incompatible (vous pouvez rien y faire désolé)"
		)


@rpc("any_peer")
func show_error_to_user(error_message: String):
	ErrorPanel_Label.text = error_message
	ErrorPanel.show()


func show_loading_message(text: String):
	LoadingMessage_Label.text = text
	LoadingMessage.show()


func _on_peer_connected(peer_id):
	if !Lobby.is_full():
		Lobby.add_player(peer_id)
	else:
		rpc_id(peer_id, "show_error_to_user", "The lobby is full, you can't join!")
		NetworkingManager.rpc_id(peer_id, "disconnect_from_server")


func _on_peer_disconnected(peer_id):
	Lobby.rpc("remove_player_from_lobby", peer_id)


func _on_disconnected_from_server():
	Lobby.clear()
	Lobby.hide()
	show_menu()


func close_ErrorPanel() -> void:
	ErrorPanel.hide()
