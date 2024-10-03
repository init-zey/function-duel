extends Card
class_name PlusCard

var value : Complex = Complex.new(0):
	set(v):
		value = v
		card_name = "x" + v.op_to_string()

static func create(table, value, player):
	if value == null:
		return null
	if Complex.equal(value, Complex.new(0)):
		return FunctionCard.create(table, "x", player)
	var new_card = PlusCard.new()
	new_card.table = table
	new_card.value = value
	new_card.player = player
	new_card.update_face_pattern(preload("res://asset/sprite/function/add.png"))
	return new_card

func process(bottom):
	var top = self
	if bottom is FunctionCard:
			if bottom.card_name == "ln(x)":
				return [FunctionCard.create(table, "ln(x)", bottom.player), MultiplyCard.create(table, Complex.exp(bottom.value), top.player)]
			elif bottom is PlusCard:
				return [PlusCard.create(table, Complex.plus(self.value, bottom.value), bottom.player)]
	elif bottom is ValueCard:
		return [ValueCard.create(table, Complex.plus(self.value, bottom.value), bottom.player)]
