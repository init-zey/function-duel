extends ColorRect
class_name Table

@export var resolution : Vector2:
	set(value):
		resolution = value
		material.set_shader_parameter("resolution", value)
@export var even_confirm_rate : float:
	set(v):
		even_confirm_rate = v
		material.set_shader_parameter("left_blued_rate", v)
@export var odd_confirm_rate : float:
	set(v):
		odd_confirm_rate = v
		material.set_shader_parameter("right_blued_rate", v)
@export var even : Player
@export var odd : Player
@export var card_stack : CardStack
@export var highlight_value_card : ValueCard = null:
	set(v):
		if highlight_value_card != v:
			if highlight_value_card != null:
				var tweener = create_tween()
				tweener.tween_property(highlight_value_card, "highlight_rate", 0, 0.2)
			if v != null:
				var tweener = create_tween()
				tweener.tween_property(v, "highlight_rate", 1, 0.2)
		highlight_value_card = v
@export var vertical : bool = false:
	set(v):
		vertical = v
		even.vertical = v
		odd.vertical = v
		for card in cards:
			card.vertical = v

var piles : Array
var cards : Array

var shader_time : float = 0

var dragging : bool = false

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	material = ShaderMaterial.new()
	material.shader = preload("res://shader/table.gdshader")
	self.resized.connect(on_resized)

func _on_viewport_size_changed():
	var window_size = get_window().size
	size = window_size
	if window_size.x <= 540:
		size.x = 540
		size.y = float(window_size.y) / float(window_size.x) * size.x
	if window_size.y <= 540:
		size.y = 540
		size.x = float(window_size.x) / float(window_size.y) * size.y
	scale = Vector2(window_size) / size
func on_resized():
	resolution = size/4
	vertical = size.y > size.x

func compose(bottom_card, top_card):
	var pile = Pile.new()
	pile.table = self
	add_child(pile)
	pile.position = bottom_card.center_position
	if bottom_card.pile != null:
		if bottom_card.pile.top.player != bottom_card.player and top_card.player == bottom_card.player:
			pile.hard_compose = true
		bottom_card.pile.dismiss()
		await get_tree().create_timer(0.5).timeout
	pile.bottom = bottom_card
	pile.top = top_card
	pile.style = Pile.Style.TIGHT
		

func _gui_input(e):
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.is_pressed():
				dragging = true
			else:
				dragging = false
	elif e is InputEventMouseMotion:
		if dragging:
			if e.relative.y >= 20:
				if e.position.x < size.x / 2:
					even.confirmed = true
				else:
					odd.confirmed = true
			elif e.relative.y <= -20:
				if e.position.x < size.x / 2:
					even.confirmed = false
				else:
					odd.confirmed = false
func _process(delta):
	shader_time += delta * (1.0-(even_confirm_rate + odd_confirm_rate)*0.5)
	material.set_shader_parameter("mtime", shader_time)

func global_confirm():
	even.confirmed = false
	odd.confirmed = false
	for pile in piles:
		pile.style = Pile.Style.LOOSE
		get_tree().create_timer(0.2).timeout.connect(pile.to_process)
	if len(card_stack.cards) >= 2:
		card_stack.deal()
	else:
		await get_tree().create_timer(1).timeout
		dissolve_rest()

func on_value_card_entered():
	var winner_card = find_winner_card()
	if winner_card != null:
		highlight_value_card = winner_card
			
func find_winner_card():
	var winner_card = null
	var winner_value = -INF
	for card in cards:
		if card.player != null and card is ValueCard:
			if is_equal_approx(card.value.imag, 0) and card.value.real >= winner_value:
				if is_equal_approx(card.value.real, winner_value):
					if int(winner_value)%2 != (0 if winner_card.player.player_name == "even" else 1):
						continue
				winner_value = card.value.real
				winner_card = card
	return winner_card

func dissolve_rest():
	for card in cards:
		if card != highlight_value_card:
			var tweener = create_tween()
			tweener.tween_property(card, "dissolve_value", 0, 0.2)
		else:
			var tweener = create_tween()
			tweener.tween_property(card, "height", 32, 0.2)

#region debug command
func clear():
	for card in cards:
		card.queue_free()
	self.cards = []
	card_stack.cards = []

func add_card(card):
	self.add_child(card)
	card.on_enter_table()
	card.center_position = get_global_mouse_position()

func add_value(real, imag, player):
	add_card(ValueCard.create(self, Complex.new(real, imag), player))
#endregion

#region multiplayer support

enum GameState{
	LOCAL_PLAYING,
	SERVER_PLAYING,
	CLIENT_PLAYING,
	PURE_SERVER,
	MENU,
}

@export var game_state : GameState = GameState.LOCAL_PLAYING
@export var server_player_name : Player

#endregion
