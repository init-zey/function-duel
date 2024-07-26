extends ColorRect
class_name Table

signal game_end

@export var resolution : Vector2:
	set(v):
		resolution = v
		if water_top and water_bottom:
			water_top.material.set_shader_parameter("resolution", v)
			water_bottom.material.set_shader_parameter("right_blued_rate", v)
@export var even_confirm_rate : float:
	set(v):
		even_confirm_rate = v
		water_top.material.set_shader_parameter("left_blued_rate", v)
@export var odd_confirm_rate : float:
	set(v):
		odd_confirm_rate = v
		water_top.material.set_shader_parameter("right_blued_rate", v)
@export var even : Player
@export var odd : Player
@export var card_stack : Node
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
		water_top.material.set_shader_parameter("vertical", v)
		water_bottom.material.set_shader_parameter("vertical", v)
@export var water_top : ColorRect
@export var water_bottom : ColorRect

var piles : Array
var cards : Array

var shader_time : float = 0

var dragging : bool = false
var current_player : Player = null:
	set(v):
		current_player = v
		if not v == null:
			v.current = true
			v.opposite_player.current = false
		else:
			even.current = true
			odd.current = true

@export var card_canvas_group : CanvasGroup

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	self.resized.connect(on_resized)

func start():
	get_viewport().size_changed.emit()
	card_stack.start()

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
			var asize = size
			var arelative = e.relative
			var aposition = e.position
			if vertical:
				var t = asize.y
				asize.y = asize.x
				asize.x = t
				t = arelative.y
				arelative.y = arelative.x
				arelative.x = t
				t = aposition.y
				aposition.y = aposition.x
				aposition.x = t
			if arelative.y >= 20:
				if aposition.x < asize.x / 2:
					if network.sender_name == "even" or network.sender_name == "local":
						if network.multiplayer.multiplayer_peer:
							even.confirm.rpc()
						else:
							even.confirm()
				else:
					if network.sender_name == "odd" or network.sender_name == "local":
						if network.multiplayer.multiplayer_peer:
							odd.confirm.rpc()
						else:
							odd.confirm()
			elif arelative.y <= -20:
				if aposition.x < asize.x / 2:
					if network.sender_name == "even" or network.sender_name == "local":
						if network.multiplayer.multiplayer_peer:
							even.disconfirm.rpc()
						else:
							even.disconfirm()
				else:
					if network.sender_name == "odd" or network.sender_name == "local":
						if network.multiplayer.multiplayer_peer:
							odd.disconfirm.rpc()
						else:
							odd.disconfirm()

func _process(delta):
	shader_time += delta * (1.0-(even_confirm_rate + odd_confirm_rate)*0.5)
	water_top.material.set_shader_parameter("mtime", shader_time)
	water_bottom.material.set_shader_parameter("mtime", shader_time)

func global_confirm():
	if network.is_host():
		if network.multiplayer.multiplayer_peer:
			even.disconfirm.rpc()
			odd.disconfirm.rpc()
		else:
			even.disconfirm()
			odd.disconfirm()
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
			card.dissolve()
		else:
			var tweener = create_tween()
			tweener.tween_property(card, "height", 32, 0.2)
	await get_tree().create_timer(1).timeout
	player_win(highlight_value_card.player)

#region debug command
func clear():
	for card in cards:
		card.queue_free()
	self.cards = []
	card_stack.cards = []
#endregion

func player_win(player):
	card_stack.ribbon_name = player.player_name
	var tweener = create_tween()
	card_stack.show_ribbon = true
	tweener.set_parallel().tween_property(card_stack, "ribbon_color", player.card_color, 0.2)
	await get_tree().create_timer(3).timeout
	tweener.set_parallel().tween_property(card_stack, "ribbon_color", Color.WHITE, 0.2)
	card_stack.show_ribbon = false
	await get_tree().create_timer(3).timeout
	game_end.emit()

func on_global_reset():
	for pile in piles:
		pile.queue_free()
	for card in cards:
		card.dissolve()
