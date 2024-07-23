@tool
extends Control
class_name Pile

enum Style{
	TIGHT,
	LOOSE,
	LINE,
	OVERLAP
}

@export var table : Table
@export var style : Pile.Style
@export var bottom : Card:
	set(v):
		var prev_bottom = bottom
		bottom = v
		if bottom != null:
			bottom.pile = self
		if prev_bottom != bottom and prev_bottom != null:
			prev_bottom.pile = null
@export var top : Card:
	set(v):
		var prev_top = top
		top = v
		if top != null:
			top.pile = self
		if prev_top != top and prev_top != null:
			prev_top.pile = null

var leaving_flag : bool = false
var hard_compose : bool = false

var tween_position : Vector2:
	set(v):
		var position_tweener = create_tween()
		position_tweener.tween_property(self, "position", v, 0.2)

func _ready():
	size = Vector2(0, 0)
	
	self.table.piles.append(self)
	
func _process(delta):
	if not bottom == null and not top == null:
		var shake_diff = Vector2()
		if hard_compose:
			shake_diff = 4 * Vector2(randf()-0.5, randf()-0.5)
		if style == Pile.Style.TIGHT:
			bottom.lerp_angle = 0
			bottom.tween_center_position = position + Vector2(0, 8) + shake_diff
			top.lerp_angle = 0
			top.tween_center_position = position + Vector2(0, -8) + shake_diff
		elif style == Pile.Style.LOOSE:
			bottom.lerp_angle = -PI/24
			bottom.tween_center_position = position + Vector2(bottom.real_card_size.x/2, 0) + shake_diff
			top.lerp_angle = PI/24
			top.tween_center_position = position + Vector2(-top.real_card_size.x/2, 0) + shake_diff

func _exit_tree():
	table.piles.erase(self)
	if bottom != null:
		bottom.queue_free()
	if top != null:
		top.queue_free()

func dismiss():
	style = Style.LOOSE
	leaving_flag = true
	await get_tree().create_timer(0.2).timeout
	self.bottom.withdraw()
	self.top.withdraw()
	var prev_bottom = self.bottom
	var prev_top = self.top
	self.bottom = null
	self.top = null
	queue_free()

func switch_tight_loose():
	style = Style.LOOSE if style == Style.TIGHT else Style.TIGHT

func to_process():
	if leaving_flag:
		return
	self.bottom.tween_center_position = position
	self.top.tween_center_position = position
	self.bottom.revolve = PI/2
	self.top.revolve = -PI/2
	await get_tree().create_timer(0.2).timeout
	queue_free()
	var process_result = top.process(bottom)
	for index in range(len(process_result)):
		var card = process_result[index]
		var ref_index = index - (len(process_result) - 1)/2
		table.add_child(card)
		card.center_position = self.position + Vector2(ref_index * card.real_card_size.x, 0)
		card.revolve = PI/2
		card.tween_revolve = 0
		get_tree().create_timer(0.2).timeout.connect(card.on_enter_table)
