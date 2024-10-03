extends Card
class_name RemainderCard

var value : Complex = Complex.new(1):
	set(v):
		value = v
		card_name = "x mod " + v.to_string()

static func create(table, value, player):
	if value == null:
		return null
	if not value.imag == 0:
		return null
	var new_card = RemainderCard.new()
	new_card.table = table
	new_card.value = value
	new_card.player = player
	new_card.update_face_pattern(preload("res://asset/sprite/function/mod.png"))
	return new_card
	
func process(bottom):
	var top = self
	if bottom is RemainderCard:
			if self.value.real > bottom.value.real:
				return [RemainderCard.create(table, bottom.value, top.player)]
	elif bottom is ValueCard:
		if not bottom.value.imag == 0:
			return null
		return [ValueCard.create(table, Complex.new(fmod(bottom.value.real, self.value.real)), bottom.player)]
