extends ColorRect
class_name Table

signal game_end(winner)
signal cards_updated()

@export var resolution : Vector2:
	set(v):
		resolution = v
		if water_top and water_bottom:
			water_top.material.set_shader_parameter("resolution", v)
			water_bottom.material.set_shader_parameter("resolution", v)
			stone_group.material.set_shader_parameter("resolution", v)
			
			material.set_shader_parameter("resolution", v)
@export var even_confirm_rate : float:
	set(v):
		even_confirm_rate = v
		water_top.material.set_shader_parameter("left_blued_rate", v)
		material.set_shader_parameter("left_blued_rate", v)
@export var odd_confirm_rate : float:
	set(v):
		odd_confirm_rate = v
		water_top.material.set_shader_parameter("right_blued_rate", v)
		material.set_shader_parameter("right_blued_rate", v)
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
		
		material.set_shader_parameter("vertical", v)
@export var water_top : ColorRect
@export var water_bottom : ColorRect
@export var win_sound : AudioStreamPlayer
@export var lose_sound : AudioStreamPlayer

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
@export var stone_group : CanvasGroup

var information_visible : bool = false:
	set(v):
		information_visible = v
		card_stack.bottom_label.visible = v
		even.score_label.visible = v
		odd.score_label.visible = v

func _ready():
	self.resized.connect(on_resized)

func start():
	card_stack.start()

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
		if dragging and card_stack.start_complete:
			var asize = size
			var arelative = e.relative
			var aposition = e.position
			if vertical:
				var t = asize.y
				asize.y = asize.x
				asize.x = t
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
	card_canvas_group.material.set_shader_parameter("mtime", shader_time)
	stone_group.material.set_shader_parameter("mtime", shader_time)
	
	material.set_shader_parameter("mtime", shader_time)

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
		card_stack.start_complete = false
		await get_tree().create_timer(1).timeout
		dissolve_rest()

func on_value_card_entered():
	var winner_card = find_winner_card()
	if winner_card != null:
		highlight_value_card = winner_card
			
func find_winner_card():
	var r
	if even.score > odd.score:
		r = even.maximum_card
	elif even.score < odd.score:
		r = odd.maximum_card
	else:
		r = even.maximum_card if int(even.score)%2==0 else odd.maximum_card
	return r

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
	if player.player_name == network.sender_name or network.sender_name == "local":
		win_sound.play()
	else:
		lose_sound.play()
	card_stack.ribbon_name = player.player_name
	var tweener = create_tween()
	card_stack.show_ribbon = true
	tweener.set_parallel().tween_property(card_stack, "ribbon_color", player.card_color, 0.2)
	await get_tree().create_timer(3).timeout
	tweener.set_parallel().tween_property(card_stack, "ribbon_color", Color.WHITE, 0.2)
	card_stack.show_ribbon = false
	await get_tree().create_timer(3).timeout
	game_end.emit(player)

func on_global_reset(manually):
	for pile in piles:
		pile.queue_free()
	for card in cards:
		card.dissolve()
	even.disconfirm()
	odd.disconfirm()
