@tool
extends Label
class_name Player

@export var table : Table
@export var player_name : String
@export var rect : Rect2
@export var opposite_player : Player
@export var confirmed : bool
@export var card_color : Color = Color.WHITE:
	set(v):
		card_color = v
		self.modulate = card_color
@export var custom_player_name : String = "default_player":
	set(v):
		custom_player_name = v
		update_text()
@export var v_anchor : Vector2
@export var v_bottom_offset : float
@export var v_top_offset : float
@export var v_right_offset : float
@export var v_left_offset : float
@export var h_anchor : Vector2
@export var h_bottom_offset : float
@export var h_top_offset : float
@export var h_right_offset : float
@export var h_left_offset : float
@export var vertical : bool = false:
	set(v):
		vertical = v
		if v:
			set_anchor_and_offset(SIDE_TOP, v_anchor.y, v_top_offset, true)
			set_anchor_and_offset(SIDE_BOTTOM, v_anchor.y, v_bottom_offset, true)
			set_anchor_and_offset(SIDE_LEFT, v_anchor.x, v_left_offset, true)
			set_anchor_and_offset(SIDE_RIGHT, v_anchor.x, v_right_offset, true)
		else:
			set_anchor_and_offset(SIDE_TOP, h_anchor.y, h_top_offset, true)
			set_anchor_and_offset(SIDE_BOTTOM, h_anchor.y, h_bottom_offset, true)
			set_anchor_and_offset(SIDE_LEFT, h_anchor.x, h_left_offset, true)
			set_anchor_and_offset(SIDE_RIGHT, h_anchor.x, h_right_offset, true)
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
	text = ("-{0}-" if current else "{0}").format([custom_player_name])
	
