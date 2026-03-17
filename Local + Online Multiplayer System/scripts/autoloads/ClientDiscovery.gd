extends Node

var udp := PacketPeerUDP.new()
var listen_port := 7777
var discovered_host := ""

signal host_found(host: String)

func _ready():
	udp.bind(listen_port)

func _process(_delta):
	if udp.get_available_packet_count() > 0:
		var bytes := udp.get_packet()
		var text := bytes.get_string_from_utf8()
		if text == "GODOT_LOBBY":
			discovered_host = udp.get_packet_ip()
			emit_signal("host_found", discovered_host)
