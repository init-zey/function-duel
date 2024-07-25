extends Control

signal global_reseted()

@onready var table := $Table
@onready var user_console := $UserConsole
@onready var console_label := $UserConsole/RichTextLabel
@onready var line_edit := $UserConsole/HBoxContainer/LineEdit
@onready var main_h_box := $MainHBox
@onready var host_v_box := $HostVBox
@onready var join_v_box := $JoinVBox
@onready var lobby_panel := $LobbyPanel
@onready var even_color_picker := $LobbyPanel/MarginContainer/VBoxContainer/PlayerList/VBoxContainer/even/EvenColorPickerButton
@onready var odd_color_picker := $LobbyPanel/MarginContainer/VBoxContainer/PlayerList/VBoxContainer/odd/OddColorPickerButton
@onready var even_online_label := $LobbyPanel/MarginContainer/VBoxContainer/PlayerList/VBoxContainer/even/Label
@onready var odd_online_label := $LobbyPanel/MarginContainer/VBoxContainer/PlayerList/VBoxContainer/odd/Label
@onready var lobby_start_button := $LobbyPanel/MarginContainer/VBoxContainer/StartButton
@onready var restart_button := $RestartButton
var time_string : String:
	get:
		return "<"+Time.get_time_string_from_system()+">"
var console_avaiable : bool = false

func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	ui_reset()
	table.game_end.connect(on_game_end)
	global_reseted.connect(table.on_global_reset)
	global_reseted.connect(self.on_global_reset)

func _input(event):
	if event is InputEventKey:
		if console_avaiable and user_console.visible:
			if Input.is_action_just_released("ui_accept"):
				send_local_message()
		if console_avaiable and Input.is_action_just_pressed("toggle_user_console"):
			user_console.visible = !user_console.visible

@rpc("any_peer", "call_local")
func append(other_sender_name, message):
	user_console_push("{0}:{1}".format([other_sender_name, message]))

func _on_host_panel_button_pressed():
	main_h_box.visible = false
	host_v_box.visible = true

func _on_join_panel_button_pressed():
	main_h_box.visible = false
	join_v_box.visible = true

func _on_host_button_pressed():
	host_v_box.visible = false
	var port = $HostVBox/LineEdit.text
	var selection_item_list : ItemList = $HostVBox/CustomNameSelection
	var selected_names = selection_item_list.get_selected_items()
	var custom_name = ""
	if len(selected_names) > 0:
		custom_name = selection_item_list.get_item_text(selected_names[0])
	else:
		custom_name = "even"
	network.create_server(
		7777 if port == "" else int(port),
		"even" if custom_name == "" else custom_name
	)
	console_avaiable = true
	user_console_push("服务器已建立！")
	show_lobby()
	turn_online(network.sender_name)
	if network.sender_name == "even":
		even_color_picker.disabled = false
	elif network.sender_name == "odd":
		odd_color_picker.disabled = false

func _peer_connected(peer_id):
	if peer_id == 1:
		user_console_push("已连接到服务器。")
		var unique_id = multiplayer.get_unique_id()
		register_sender.rpc_id(1, unique_id)
		join_v_box.visible = false
		ask_update.rpc()

func _peer_disconnected(peer_id):
	turn_offline(network.sender_list[peer_id])
	if peer_id == 1:
		user_console_push("服务端断开。")
	else:
		var client_name = network.sender_list[peer_id]
		user_console_push("客户端断开，名称：" + client_name)
		if client_name == "odd" or client_name == "even":
			lobby_start_button.disabled = true
	network.sender_list.erase(peer_id)

@rpc("any_peer")
func register_sender(unique_id):
	var other_sender_name = "odd" if network.sender_name == "even" else "even"
	network.sender_list[unique_id] = other_sender_name
	update_sender_list.rpc_id(unique_id, network.sender_list)
	user_console_push("客户端已连接，名称：" + other_sender_name)
	turn_online(other_sender_name)
	lobby_start_button.disabled = false

@rpc
func update_sender_list(new_sender_list):
	network.sender_list = new_sender_list
	network.sender_name = network.sender_list[network.multiplayer.get_unique_id()]
	if network.sender_name == "even":
		even_color_picker.disabled = false
	elif network.sender_name == "odd":
		odd_color_picker.disabled = false
	turn_online(new_sender_list[1])
	join_complete()

func user_console_push(message):
	console_label.text += time_string + message + "\n"

func _on_join_button_pressed():
	var ip = $JoinVBox/IpLineEdit.text
	var port = $JoinVBox/PortLineEdit.text
	network.terminate_networking()
	network.create_client(
		ip,
		7777 if port == "" else int(port),
	)
	var bottom_label = $JoinVBox/BottomLabel
	bottom_label.modulate = Color.WHITE
	bottom_label.text = "JOINING..."
	bottom_label.visible = true

func _on_send_button_pressed():
	send_local_message()

func send_local_message():
	append.rpc(network.sender_name, line_edit.text)
	line_edit.text = ""

func _on_join_back_button_pressed():
	ui_reset()
	$JoinVBox/BottomLabel.visible = false

func _on_host_back_button_pressed():
	ui_reset()

func join_complete():
	console_avaiable = true
	show_lobby()
	turn_online(network.sender_name)

func turn_online(sender_name):
	if sender_name == "even":
		even_online_label.text = "even ✔"
	else:
		odd_online_label.text = "odd ✔"

func turn_offline(sender_name):
	if sender_name == "even":
		even_online_label.text = "even ❌"
	else:
		odd_online_label.text = "odd ❌"


func _on_lobby_start_button_pressed():
	game_start.rpc()

func _on_lobby_back_button_pressed():
	ui_reset()

@rpc('call_local')
func game_start():
	lobby_panel.visible = false
	table.current_player = {"even":table.even, "odd":table.odd, "local":null}[network.sender_name]
	table.start()

func ui_reset():
	console_avaiable = false
	main_h_box.visible = true
	host_v_box.visible = false
	join_v_box.visible = false
	lobby_panel.visible = false
	lobby_start_button.disabled = true
	even_color_picker.disabled = true
	odd_color_picker.disabled = true
	table.card_stack.ribbon_label.text = "[center][wave amp=50.0 freq=5.0 connected=1][font size=100]FUNCTION [font size=150]DUEL"
	table.card_stack.ribbon_color = Color.WHITE
	table.card_stack.show_ribbon = true
	table.even.visible = false
	table.odd.visible = false
	restart_button.visible = false
	turn_offline("even")
	turn_offline("odd")
	network.terminate_networking()

func _on_even_color_picker_button_color_changed(color):
	even_color_changed.rpc(color)
	table.even.card_color = even_color_picker.color

func _on_odd_color_picker_button_color_changed(color):
	odd_color_changed.rpc(color)
	table.odd.card_color = odd_color_picker.color

@rpc('any_peer')
func even_color_changed(new_color):
	even_color_picker.color = new_color
	table.even.card_color = even_color_picker.color

@rpc('any_peer')
func odd_color_changed(new_color):
	odd_color_picker.color = new_color
	table.odd.card_color = odd_color_picker.color

func show_lobby():
	lobby_panel.visible = true
	table.even.visible = true
	table.odd.visible = true
	table.card_stack.show_ribbon = false

@rpc('any_peer')
func ask_update():
	assert(network.is_host())
	even_color_changed.rpc(even_color_picker.color)
	odd_color_changed.rpc(odd_color_picker.color)

func on_game_end():
	global_reseted.emit()

func on_global_reset():
	if network.is_host():
		restart_button.visible = true

func _on_restart_button_pressed():
	if network.sender_name != "local":
		to_lobby.rpc()
		restart_button.visible = false
	else:
		ui_reset()

@rpc('call_local')
func to_lobby():
	lobby_panel.visible = true

func _on_local_play_panel_button_pressed():
	network.sender_name = "local"
	main_h_box.visible = false
	table.card_stack.show_ribbon = false
	table.even.visible = true
	table.odd.visible = true
	game_start()
