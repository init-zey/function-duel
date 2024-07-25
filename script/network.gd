extends Node

var sender_name = null
var sender_list : Dictionary

func create_server(port, custom_name):
	var peer = ENetMultiplayerPeer.new()
	var res = peer.create_server(port, 32)
	multiplayer.multiplayer_peer = peer
	sender_name = custom_name
	sender_list[1] = sender_name
	return res

func create_client(ip, port):
	var peer = ENetMultiplayerPeer.new()
	var res = peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	return res

func terminate_networking():
	multiplayer.multiplayer_peer = null
	sender_list = {}
	sender_name = null

func is_host():
	return sender_name == "local" or multiplayer.is_server()
