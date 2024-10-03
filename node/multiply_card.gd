extends Card
class_name MultiplyCard

var value : Complex = Complex.new(0):
	set(v):
		value = v
		card_name = v.mul_to_string() + "x"

static func create(table, value, player):
	if value == null:
		return null
	if Complex.equal(value, Complex.new(0)):
		return ValueCard.create(table, Complex.new(0), player)
	var new_card = MultiplyCard.new()
	new_card.table = table
	new_card.value = value
	new_card.player = player
	new_card.update_face_pattern(preload("res://asset/sprite/function/mul.png"))
	return new_card
	

func process(bottom):
	var top = self
	if bottom is FunctionCard:
		if bottom.card_name == "ln(x)":
			if Complex.equal(value, Complex.new(-1)):
				return [FunctionCard.create(table, "ln(x)", bottom.player), FunctionCard.create(table, "1/x", top.player)]
			elif Complex.equal(value, Complex.new(2)):
				return [FunctionCard.create(table, "ln(x)", bottom.player), FunctionCard.create(table, "x^2", top.player)]
			elif Complex.equal(value, Complex.new(0.5)):
				return [FunctionCard.create(table, "ln(x)", bottom.player), FunctionCard.create(table, "sqrt(x)", top.player)]
		elif bottom.card_name == "exp(x)":
			return [FunctionCard.create(table, "exp(x)", bottom.player), MultiplyCard.create(table, Complex.ln(bottom.value), top.player)]
		elif bottom is MultiplyCard:
			return [MultiplyCard.create(table, Complex.multiply(self.value, bottom.value), bottom.player)]
	elif bottom is ValueCard:
		return [ValueCard.create(table, Complex.multiply(self.value, bottom.value), bottom.player)]
