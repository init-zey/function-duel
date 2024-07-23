@tool
extends Card
class_name ValueCard

var value : Complex = Complex.new(0):
	set(v):
		value = v
		card_name = v.to_string()

var highlight_rate : float:
	set(v):
		highlight_rate = v
		material.set_shader_parameter("maxhighlight_rate", v)

static func create(table, value, player):
	if value == null:
		return null
	var new_card = ValueCard.new()
	new_card.table = table
	new_card.value = value
	new_card.player = player
	return new_card

func process(bottom):
	return null
