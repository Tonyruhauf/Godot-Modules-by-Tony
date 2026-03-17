extends Node


const PORT = 2046

var enet_peer = ENetMultiplayerPeer.new()
var server_ip_adress: String

signal server_started
signal server_joined
signal server_closed
signal disconnected_from_server
signal peer_connected(peer_id)
signal peer_disconnected(peer_id)
signal upnp_setup_failed(message: String)


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)


func create_server(local: bool):
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(on_peer_connected)
	multiplayer.peer_disconnected.connect(on_peer_disconnected)
	
	if !local:
		if not upnp_setup():
			close_server()
			return
	
	server_started.emit()


func join_server(encoded_adress: String) -> Error:
	if encoded_adress.is_empty(): return Error.ERR_INVALID_PARAMETER
	if not is_adress_encoding_valid(encoded_adress): return Error.ERR_INVALID_PARAMETER
	
	var result
	print(decode_adress(encoded_adress))
	result = enet_peer.create_client(decode_adress(encoded_adress), PORT)
	
	if result == OK:
		multiplayer.multiplayer_peer = enet_peer
		server_joined.emit()
	
	return result


func close_server():
	# Disconnect all signals
	multiplayer.peer_connected.disconnect(on_peer_connected)
	multiplayer.peer_disconnected.disconnect(on_peer_disconnected)
	
	for peer in multiplayer.get_peers():
		rpc_id(peer, "disconnect_from_server")
	
	await get_tree().create_timer(0.5).timeout
	
	# Stop hosting
	enet_peer.close()  # Properly closes the ENet server
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()  # Unset the peer
	
	server_closed.emit()


@rpc("any_peer")
func disconnect_from_server():
	multiplayer.multiplayer_peer = null
	enet_peer.close()
	disconnected_from_server.emit()


func on_peer_connected(peer_id):
	peer_connected.emit(peer_id)


func on_peer_disconnected(peer_id):
	peer_disconnected.emit(peer_id)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_hosting_server():
			await close_server()
		get_tree().quit()


func is_hosting_server():
	if !is_server_running(): return false
	if !multiplayer.is_server(): return false
	return true


func is_server_running():
	if !multiplayer.has_multiplayer_peer(): return false
	if enet_peer.get_connection_status() == 0: return false
	return true


func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		upnp_failed("UPNP Discover Failed! Error %s" % discover_result, Engine.is_editor_hint())
		return false
	
	if not (upnp.get_gateway() and upnp.get_gateway().is_valid_gateway()):
		upnp_failed("UPNP Invalid Gateway!", Engine.is_editor_hint())
		return false

	var map_result = upnp.add_port_mapping(PORT)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		upnp_failed("UPNP Port Mapping Failed! Error %s" % map_result, Engine.is_editor_hint())
		return false
	
	print("Success! Join Address: %s" % upnp.query_external_address())
	server_ip_adress = encode_adress(upnp.query_external_address())
	return true


func upnp_failed(message: String, send_error: bool):
	assert(!send_error, message)
	printerr(message)
	upnp_setup_failed.emit()


func get_local_ip_adress():
	for address in IP.get_local_addresses():
		if not address.begins_with("127.") and address.find(":") == -1:
			return address
	return ""


func encode_adress(ip: String):
	var encoded_ip = ""
	var encoding_dic = {
		"0": "a",
		"1": "k",
		"2": "c",
		"3": "t",
		"4": "e",
		"5": "f",
		"6": "p",
		"7": "u",
		"8": "i",
		"9": "r",
	}
	
	for character in ip:
		if character == ".":
			encoded_ip += ["w", "x", "y", "z"].pick_random()
		else:
			encoded_ip += encoding_dic[character]
	
	return encoded_ip


func decode_adress(encoded_ip: String):
	var decoded_ip = ""
	var encoding_dic = {
		"0": "a",
		"1": "k",
		"2": "c",
		"3": "t",
		"4": "e",
		"5": "f",
		"6": "p",
		"7": "u",
		"8": "i",
		"9": "r",
	}
	
	for character in encoded_ip:
		if ["w", "x", "y", "z"].has(character):
			decoded_ip += "."
		else:
			decoded_ip += encoding_dic.find_key(character)
	
	return decoded_ip


func is_adress_encoding_valid(encoded_ip: String):
	var valid_chars = [
		"a",
		"k",
		"c",
		"t",
		"e",
		"f",
		"p",
		"u",
		"i",
		"r",
		"w",
		"x",
		"y",
		"z"
	]
	
	for character in encoded_ip:
		if not valid_chars.has(character):
			return false
	
	return true
