extends Control

@onready var chatting_label := $ChattingLabel
@onready var line_edit := $ChattingLabel/HBoxContainer/LineEdit
@onready var main_h_Box := $MainHBox
@onready var host_v_box := $HostVBox
@onready var join_v_box := $JoinVBox
var sender_name : String
var time_string : String:
	get:
		return "<"+Time.get_time_string_from_system()+">"
var sender_list : Dictionary

func host(port, custom_name):
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 32)
	multiplayer.multiplayer_peer = peer
	sender_name = custom_name
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)
	sender_list[1] = sender_name
	return peer

func try_join(ip, port, custom_name):
	var peer = ENetMultiplayerPeer.new()
	var res = peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	sender_name = ("CLIENT_" + str(multiplayer.get_unique_id())) if custom_name == null else custom_name
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)
	return res

func terminate_networking():
	multiplayer.multiplayer_peer = null

func _input(event):
	if event is InputEventKey and chatting_label.visible:
		if Input.is_action_just_released("ui_accept"):
			send_local_message()

@rpc("any_peer")
func append(other_sender_name, message):
	chatting_label_push("{0}:{1}".format([other_sender_name, message]))
	if multiplayer.is_server():
		append.rpc(other_sender_name, message)

func _on_host_panel_button_pressed():
	main_h_Box.visible = false
	host_v_box.visible = true

func _on_join_panel_button_pressed():
	main_h_Box.visible = false
	join_v_box.visible = true

func _on_host_button_pressed():
	host_v_box.visible = false
	var port = $HostVBox/LineEdit.text
	var custom_name = $HostVBox/LineEdit2.text
	host(
		7777 if port == "" else int(port),
		"SERVER" if custom_name == "" else custom_name
	)
	chatting_label.visible = true
	chatting_label_push("服务器已建立！")

func _on_multiplayer_peer_connected(peer_id):
	if peer_id == 1:
		chatting_label_push("已连接到服务器，按N查看已连接用户列表。")
		var unique_id = multiplayer.get_unique_id()
		register_sender.rpc(sender_name, unique_id)

func _on_multiplayer_peer_disconnected(peer_id):
	if peer_id == 1:
		chatting_label_push("服务端断开。")
	else:
		chatting_label_push("客户端断开，名称：" + sender_list[peer_id])

@rpc("any_peer")
func register_sender(other_sender_name, unique_id):
	sender_list[unique_id] = other_sender_name
	if multiplayer.is_server():
		update_sender_list.rpc(sender_list)
		chatting_label_push("客户端已连接，名称：" + other_sender_name)

@rpc("any_peer")
func update_sender_list(new_sender_list):
	if not multiplayer.is_server():
		sender_list = new_sender_list

func chatting_label_push(message):
	chatting_label.text += time_string + message + "\n"

func _on_join_button_pressed():
	var ip = $JoinVBox/IpLineEdit.text
	var port = $JoinVBox/PortLineEdit.text
	var custom_name = $HostVBox/LineEdit2.text
	terminate_networking()
	var res = try_join(
		ip,
		7777 if port == "" else int(port),
		null if custom_name == "" else custom_name
	)
	var bottom_label = $JoinVBox/BottomLabel
	bottom_label.modulate = Color.WHITE
	bottom_label.text = "JOINING..."
	bottom_label.visible = true
	await multiplayer.peer_connected
	if len(multiplayer.get_peers()) == 0:
		res = ERR_DOES_NOT_EXIST
	if res == OK:
		join_v_box.visible = false
		chatting_label.visible = true
	elif res == ERR_CANT_CREATE:
		bottom_label.modulate = Color.RED
		bottom_label.text = "CAN'T CREATE CLIENT!"
		bottom_label.visible = true
	elif res ==  ERR_ALREADY_IN_USE:
		bottom_label.modulate = Color.RED
		bottom_label.text = "ALREADY HAS A OPEN CONNECTION!"
		bottom_label.visible = true
	elif res == ERR_DOES_NOT_EXIST:
		bottom_label.modulate = Color.RED
		bottom_label.text = "NO SERVER!"
		bottom_label.visible = true
func _on_send_button_pressed():
	send_local_message()

func send_local_message():
	if multiplayer.is_server():
		append(sender_name, line_edit.text)
	else:
		append.rpc(sender_name, line_edit.text)
	line_edit.text = ""


func _on_join_back_button_pressed():
	join_v_box.visible = false
	main_h_Box.visible = true
	$JoinVBox/BottomLabel.visible = false

func _on_host_back_button_pressed():
	host_v_box.visible = false
	main_h_Box.visible = true
