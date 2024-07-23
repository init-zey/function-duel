extends Card
class_name ModifyCard

static func create(table, card_name, player):
	var new_card = ModifyCard.new()
	new_card.table = table
	new_card.card_name = card_name
	new_card.player = player
	return new_card

func process(bottom):
	var top = self
	if bottom is FunctionCard:
		if bottom.function_name == FunctionCard.FunctionName.X:
			return [ValueCard.create(table, Complex.new(1, 0), bottom.player)]
		elif bottom.function_name == FunctionCard.FunctionName.REVERSE:
			return [FunctionCard.create(table, FunctionCard.FunctionName.REVERSE, bottom.player), FunctionCard.create(table, FunctionCard.FunctionName.SQR, bottom.player), MultiplyCard.create(table, Complex.new(-1, 0), bottom.player)]
		elif bottom.function_name == FunctionCard.FunctionName.EXP:
			return [FunctionCard.create(table, FunctionCard.FunctionName.EXP, bottom.player)]
		elif bottom.function_name == FunctionCard.FunctionName.LOG:
			return [FunctionCard.create(table, FunctionCard.FunctionName.REVERSE, bottom.player)]
		elif bottom.function_name == FunctionCard.FunctionName.SQR:
			return [MultiplyCard.create(table, Complex.new(2, 0), bottom.player)]
		elif bottom.function_name == FunctionCard.FunctionName.SQRT:
			return [FunctionCard.create(table, FunctionCard.FunctionName.REVERSE, bottom.player), FunctionCard.create(table, FunctionCard.FunctionName.SQRT, bottom.player), MultiplyCard.create(table, Complex.new(2, 0), bottom.player)]
		elif bottom.function_name == FunctionCard.FunctionName.ABS:
			return [FunctionCard.create(table, FunctionCard.FunctionName.SIGN, bottom.player)]
		elif bottom.function_name == FunctionCard.FunctionName.SIN:
			return [FunctionCard.create(table, FunctionCard.FunctionName.COS, bottom.player)]
		elif bottom.function_name == FunctionCard.FunctionName.COS:
			return [FunctionCard.create(table, FunctionCard.FunctionName.SIN, bottom.player), MultiplyCard.create(table, Complex.new(-1, 0), bottom.player)]
		elif bottom.function_name == FunctionCard.FunctionName.TAN:
			return [FunctionCard.create(table, FunctionCard.FunctionName.TAN, bottom.player), FunctionCard.create(table, FunctionCard.FunctionName.REVERSE, bottom.player), MultiplyCard.create(table, Complex.new(-1, 0), bottom.player)]
	elif bottom is PlusCard:
		return [ValueCard.create(table, Complex.new(1, 0), bottom.player)]
	elif bottom is MultiplyCard:
		return [ValueCard.create(table, bottom.value, bottom.player)]
