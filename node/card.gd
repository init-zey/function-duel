@tool
extends ColorRect
class_name Card

static func create(table, card_name, player):
	var card = Card.new()
	card.table = table
	card.card_name = card_name
	card.player = player
	card.init()
	return card

@export var table : Table:
	set(v):
		table = v
		table.resized.connect(self.on_table_resized)
@export var card_name : String:
	set(v):
		card_name = v
		
@export var height : float = 32
@export_range(0, 1) var aspect : float = 0.53
@export_range(0, 1) var round_rate : float = 0.2
@export_range(-PI, PI) var revolve : float = 0:
	set(v):
		revolve = v
		material.set_shader_parameter("revolve", v)
		queue_redraw()
var tween_revolve : float:
	set(v):
		var revolve_tweener = create_tween()
		revolve_tweener.tween_property(self, "revolve", v, 0.2)

@export var player : Player = null:
	set(v):
		player = v
@export var pile : Pile = null

@export_range(0, 1) var face_sep_line_y_rate : float = 0.8:
	set(v):
		face_sep_line_y_rate = v
		material.set_shader_parameter("face_sep_line_y_rate", v)
		queue_redraw()

var card_size : Vector2:
	get:
		return Vector2(height*aspect, height)

var dragging : bool = false
var angle : float = 0:
	set(v):
		angle = v
		material.set_shader_parameter("angle", v)
		queue_redraw()
@export var lerp_angle : float = 0
@export var confirmed : bool = false:
	set(v):
		confirmed = v
		if v:
			on_confirm()
		else:
			on_disconfirm()

var real_card_size : Vector2:
	get:
		return table_size / table.resolution * card_size

var input_rect : Rect2:
	get:
		return Rect2(center_position-real_card_size/2, real_card_size)

var center_position : Vector2:
	set(v):
		position = v - size/2
	get:
		return position + size/2
var tween_center_position : Vector2:
	set(v):
		var center_position_tweener = create_tween()
		center_position_tweener.tween_property(self, "center_position", v, 0.2)
var table_size : Vector2 = Vector2(1152, 648)
var vertical : bool = false:
	set(v):
		if vertical != v:
			var older_anchor_x = anchor.x
			anchor.x = anchor.y
			anchor.y = older_anchor_x
		vertical = v
var anchor : Vector2:
	set(v):
		if vertical:
			var older_v_x = v.x
			v.x = v.y
			v.y = older_v_x
		center_position = v * table_size
	get:
		var r = center_position / table_size
		if vertical:
			var older_r_x = r.x
			r.x = r.y
			r.y = older_r_x
		return r
@onready var prev_anchor : Vector2 = anchor
var tween_anchor : Vector2:
	set(v):
		var anchor_tweener = create_tween()
		anchor_tweener.tween_property(self, "anchor", v, 0.2)

var to_update_face_pattern : Texture2D = null
@export var dissolve_value : float = 1:
	set(v):
		dissolve_value = v
		material.set_shader_parameter("dissolve_value", v)
		if is_equal_approx(dissolve_value, 0):
			delete_self()

func _ready():
	init()

func _process(delta):
	update_size()
	angle += (lerp_angle - angle) * 0.2 * 60 * delta
	if not Rect2(0,0,1,1).has_point(self.anchor) and not dragging:
		withdraw()
	if pile == null and not confirmed:
		lerp_angle = 0
	if to_update_face_pattern:
		material.set_shader_parameter("face_pattern_texture", to_update_face_pattern)
		to_update_face_pattern = null

func _draw():
	if cos(revolve) > 0:
		var round_radius = card_size.x * round_rate
		var text_space = Rect2(
			Vector2((size.x - real_card_size.x) / 2, real_card_size.y * face_sep_line_y_rate),
			Vector2(real_card_size.x, real_card_size.y * (1 - face_sep_line_y_rate))
		).grow(-round_radius)
		var font_size = 16
		var string_size = Util.math_font.get_string_size(card_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var string_scale = min(text_space.size.x / string_size.x, text_space.size.y / string_size.y)
		var margin = (text_space.size - string_size * string_scale) / 2
		margin.y *= -1
		draw_set_transform(self.size/2, -angle, Vector2(cos(revolve), 1) * string_scale)
		draw_string(Util.math_font, (text_space.position + Vector2(0, text_space.size.y) + margin - self.size/2) / string_scale, card_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, dissolve_value))

func _exit_tree():
	table.cards.erase(self)
	if not pile == null:
		if pile.bottom == self:
			pile.bottom = null
		elif pile.top == self:
			pile.top = null

func _gui_input(e):
	if table.game_state == table.GameState.MENU:
		return
	if confirmed or cos(revolve) < 0:
		return
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.is_pressed():
				#if input_rect.has_point(e.position):
				on_lmb_press()
				if e.is_double_click():
					on_lmb_double()
			else:
				on_lmb_release()
	elif e is InputEventMouseMotion:
		on_mouse_move(e.relative)

func on_lmb_press():
	if pile == null:
		dragging = true
		get_parent().move_child(self, -1)
	else:
		pile.switch_tight_loose()

func on_lmb_double():
	if not pile == null and not pile.hard_compose:
		pile.dismiss()

func on_lmb_release():
	dragging = false
	if pile == null:
		var bottoms = []
		var compose_flag = false
		var collide_flag = false
		for card in table.cards:
			if card.input_rect.intersects(self.input_rect) and card != self:
				bottoms.append(card)
		for bottom in bottoms:
			if has_recipe(bottom) and not compose_flag:
				if cos(bottom.revolve) > 0 and bottom.pile == null or (bottom.pile != self.pile and not bottom.pile.hard_compose):
					table.compose(bottom, self)
					compose_flag = true
				else:
					collide_flag = true
			else:
				collide_flag = true
		if not compose_flag:
			if not player.rect.has_point(self.anchor):
				if not player.rect.has_point(self.prev_anchor):
					self.prev_anchor = player.random_receive_place()
				withdraw()
				collide_flag = false
			else:
				prev_anchor = anchor
		if collide_flag:
			on_collision()

func on_mouse_move(relative):
	if dragging:
		position += relative
		lerp_angle = -sign(relative.x) * PI/12

func init():
	self.color = Color.TRANSPARENT
	self.material = ShaderMaterial.new()
	self.material.shader = preload("res://shader/card.gdshader")
	self.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	self.card_name = self.card_name
	self.table.cards.append(self)
	self.on_table_resized()

func update_face_pattern(face_pattern):
	if face_pattern == null:
		return
	to_update_face_pattern = face_pattern

func withdraw():
	tween_anchor = prev_anchor

func update_size():
	var prev_center_pos = center_position
	size = Vector2(real_card_size.y, real_card_size.y)
	center_position = prev_center_pos
	material.set_shader_parameter("resolution", Vector2(card_size.y, card_size.y))
	material.set_shader_parameter("card_size", card_size)
	material.set_shader_parameter("round_rate", round_rate)

func on_table_resized():
	var older_anchor = anchor
	table_size = table.size
	anchor = older_anchor

func send_to(new_player, cpos=null):
	self.player = new_player
	if cpos == null:
		self.tween_center_position = player.receive_place(self.real_card_size)
	else:
		self.tween_center_position = table_size * (player.rect.position + player.rect.size/2) + 2 * cpos * real_card_size
	await get_tree().create_timer(0.2).timeout
	self.prev_anchor = anchor
	self.on_collision()
	self.on_enter_table()

func process(bottom):
	METHOD_FLAG_VIRTUAL

func has_recipe(bottom):
	var res = process(bottom)
	if res == null:
		return false
	for card in res:
		if card == null:
			return false
		card.queue_free()
	return true

func on_collision(t=0):
	for card in self.table.cards:
		if self.input_rect.intersects(card.input_rect) and card != self:
			var intersection_size = self.input_rect.intersection(card.input_rect).size
			var pos_diff = card.position - self.position
			var sign_vec = Vector2(0, 0)
			if abs(pos_diff.x) > abs(pos_diff.y):
				sign_vec.x = sign(pos_diff.x)
			else:
				sign_vec.y = sign(pos_diff.y)
			if sign_vec.is_equal_approx(Vector2(0, 0)):
				sign_vec = Vector2(0, -1)
			var diff_vec = intersection_size * sign_vec
			if cos(card.revolve) >= 0:
				card.tween_center_position = card.center_position + diff_vec/2
				tween_center_position = center_position - diff_vec/2
				if t<2:
					await get_tree().create_timer(0.2).timeout
					card.on_collision(t+1)
			else:
				tween_center_position = center_position - diff_vec

func set_shader_confirm_rate(value):
	material.set_shader_parameter("confirm_rate", value)

func on_confirm():
	var tweener = create_tween()
	tweener.tween_method(set_shader_confirm_rate, 0.0, 1.0, 0.2)
	if pile == null:
		tween_center_position = center_position + Vector2(0, 10)
	elif pile.bottom == self:
		pile.tween_position = pile.position + Vector2(0, 10)

func on_disconfirm():
	var tweener = create_tween()
	tweener.tween_method(set_shader_confirm_rate, 1.0, 0.0, 0.2)
	if pile == null:
		tween_center_position = center_position + Vector2(0, -10)
	elif pile.bottom == self:
		pile.tween_position = pile.position + Vector2(0, -10)

func on_enter_table():
	material.set_shader_parameter("face_bg_col", self.player.card_color)
	if self is ValueCard:
		table.on_value_card_entered()

func delete_self():
	queue_free()
	table.cards.erase(self)
	table.card_stack.cards.erase(self)
