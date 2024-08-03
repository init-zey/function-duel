@tool
extends Control
class_name Player

@export var table : Table
@export var player_label : Label
@export var player_name : String
@export var rect : Rect2
@export var opposite_player : Player
@export var confirmed : bool
@export var card_color : Color = Color.WHITE:
	set(v):
		card_color = v
		if player_label:
			player_label.modulate = card_color
@export var custom_player_name : String = "default_player":
	set(v):
		custom_player_name = v
		if player_label:
			update_text()
@export var v_to_bottom : bool = false
@export var vertical : bool = false:
	set(v):
		vertical = v
		if v:
			set_anchor(SIDE_LEFT, rect.position.y, true, false)
			set_anchor(SIDE_TOP, rect.position.x, true, false)
			set_anchor(SIDE_RIGHT, rect.end.y, true, false)
			set_anchor(SIDE_BOTTOM, rect.end.x, true, false)
			if v_to_bottom:
				var player_label_container = player_label.get_parent()
				player_label_container.set_anchor(SIDE_TOP, 1, true, false)
				player_label_container.set_anchor(SIDE_BOTTOM, 1, true, false)
				player_label_container.offset_top = -300
				player_label_container.offset_bottom = 0
		else:
			set_anchor(SIDE_LEFT, rect.position.x, true, false)
			set_anchor(SIDE_TOP, rect.position.y, true, false)
			set_anchor(SIDE_RIGHT, rect.end.x, true, false)
			set_anchor(SIDE_BOTTOM, rect.end.y, true, false)
			if v_to_bottom:
				var player_label_container = player_label.get_parent()
				player_label_container.set_anchor(SIDE_TOP, 0, true, false)
				player_label_container.set_anchor(SIDE_BOTTOM, 0, true, false)
				player_label_container.offset_top = 0
				player_label_container.offset_bottom = 300
			
@export var current : bool = false:
	set(v):
		current = v
		update_text()

func _ready():
	add_theme_font_size_override("font_size", 64)
	add_theme_font_override("font", preload("res://asset/font/ThaleahFat.ttf"))
	custom_player_name = player_name
	self.vertical = table.vertical

@rpc('call_local', 'any_peer')
func confirm():
	if confirmed:
		return
	confirmed = true
	if player_name == "even":
		var tweener = create_tween()
		tweener.tween_property(table, "even_confirm_rate", 1.0, 0.2)
	elif player_name == "odd":
		var tweener = create_tween()
		tweener.tween_property(table, "odd_confirm_rate", 1.0, 0.2)
	for card in table.cards:
		if card.player == self:
			card.confirmed = true
	if opposite_player.confirmed:
		await get_tree().create_timer(0.2).timeout
		table.global_confirm()

@rpc('call_local', 'any_peer')
func disconfirm():
	if not confirmed:
		return
	confirmed = false
	if player_name == "even":
		var tweener = create_tween()
		tweener.tween_property(table, "even_confirm_rate", 0.0, 0.2)
	elif player_name == "odd":
		var tweener = create_tween()
		tweener.tween_property(table, "odd_confirm_rate", 0.0, 0.2)
	for card in table.cards:
		if card.player == self:
			card.confirmed = false

func random_receive_place() -> Vector2:
	return rect.position + Vector2(randf(), randf()) * rect.size

func receive_place(real_card_size):
	if player_name == "even":
		return table.size/2 - Vector2(real_card_size.x, 0)
	elif player_name == "odd":
		return table.size/2 + Vector2(real_card_size.x, 0)

func update_text():
	player_label.text = ("-{0}-" if current else "{0}").format([custom_player_name])
	
