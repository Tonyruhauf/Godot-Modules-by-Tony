extends Node

var udp := PacketPeerUDP.new()
var broadcast_port := 7777
var message := "GODOT_LOBBY".to_utf8_buffer()


func _ready():
	udp.set_broadcast_enabled(true)
	udp.bind(0)	# Bind to any port
	_start_broadcast()


func _start_broadcast():
	_send_broadcast()
	await get_tree().create_timer(1.0).timeout
	_start_broadcast()


func _send_broadcast():
	udp.connect_to_host("255.255.255.255", broadcast_port)
	udp.put_packet(message)
