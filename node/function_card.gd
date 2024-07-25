@tool
extends Card
class_name FunctionCard

enum FunctionName {
	X,
	REVERSE,
	EXP,
	LOG,
	SQR,
	SQRT,
	ABS,
	ADD,
	MUL,
	MOD,
	SIN,
	COS,
	TAN,
	SIGN,
	FLOOR
}

static func create(table, function_name, player):
	var new_card = FunctionCard.new()
	new_card.table = table
	new_card.function_name = function_name
	new_card.player = player
	return new_card

@export var function_name : FunctionName:
	set(v):
		function_name = v
		card_name = {
			FunctionName.X : "x",
			FunctionName.REVERSE : "1/x",
			FunctionName.EXP : "exp(x)",
			FunctionName.LOG : "ln(x)",
			FunctionName.SQR : "x^2",
			FunctionName.SQRT : "sqrt(x)",
			FunctionName.ABS : "|x|",
			FunctionName.ADD : "x+y",
			FunctionName.MUL : "xy",
			FunctionName.MOD : "x mod y",
			FunctionName.SIN : "sin(x)",
			FunctionName.COS : "cos(x)",
			FunctionName.TAN : "tan(x)",
			FunctionName.SIGN : "sign(x)",
			FunctionName.FLOOR : "floor(x)",
		}.get(v)
		update_face_pattern({
			FunctionName.X : preload("res://asset/x.png"),
			FunctionName.EXP : preload("res://asset/exp.png"),
			FunctionName.REVERSE : preload("res://asset/reverse.png"),
			FunctionName.SQR : preload("res://asset/sqr.png"),
			FunctionName.SQRT : preload("res://asset/sqrt.png"),
		}.get(v))

func process(bottom):
	var top = self
	FunctionName
	if bottom is FunctionCard and bottom.function_name == FunctionName.X:#f⭕x = f
		return [FunctionCard.create(table, function_name, bottom.player)]
	if function_name == FunctionName.X:
		if bottom is FunctionCard:#x⭕f = f
			return [FunctionCard.create(bottom.table, bottom.function_name, bottom.player)]
		elif bottom is ValueCard:#x⭕a = a
			return [ValueCard.create(table, bottom.value, bottom.player)]
	elif function_name == FunctionName.REVERSE:
		if bottom is FunctionCard:
			if bottom.function_name == FunctionName.EXP:#1/x⭕ln(x) = -ln(x)
				return [MultiplyCard.create(table, Complex.new(-1), top.player), FunctionCard.create(table, FunctionName.EXP, bottom.player)]
			elif bottom.function_name == FunctionName.REVERSE:#1/x⭕1/x = x
				return [FunctionCard.create(table, FunctionName.X, bottom.player)]
		elif bottom is ValueCard:
			return [ValueCard.create(table, Complex.reverse(bottom.value), bottom.player)]
	elif function_name == FunctionName.EXP:
		if bottom is MultiplyCard:
			if Complex.equal(bottom.value, Complex.new(-1)):
				return [FunctionCard.create(table, FunctionName.REVERSE, bottom.player), FunctionCard.create(table, FunctionName.EXP, top.player)]
			elif Complex.new(bottom.value, Complex.new(2)):
				return [FunctionCard.create(table, FunctionName.SQR, bottom.player), FunctionCard.create(table, FunctionName.EXP, top.player)]
			elif Complex.equal(bottom.value, Complex.new(0.5)):
				return [FunctionCard.create(table, FunctionName.SQR, bottom.player), FunctionCard.create(table, FunctionName.EXP, top.player)]
			elif Complex.equal(bottom.value, Complex.new(0, 1)):
				return [MultiplyCard.create(table, Complex.new(0, 1), bottom.player), FunctionCard.create(table, FunctionName.EXP, top.player), FunctionCard.create(table, FunctionName.SIN, top.player), FunctionCard.create(table, FunctionName.COS, top.player)]
		if bottom is FunctionCard:
			if bottom.function_name == FunctionName.LOG:
				return [FunctionCard.create(table, FunctionName.X, bottom.player)]
		elif bottom is ValueCard:
			return [ValueCard.create(table, Complex.exp(bottom.value), bottom.player)]
	elif function_name == FunctionName.LOG:
		if bottom is FunctionCard:
			if bottom.function_name == FunctionName.REVERSE:
				return [MultiplyCard.create(table, Complex.new(-1), bottom.player), FunctionCard.create(table, FunctionName.LOG, top.player)]
			elif bottom.function_name == FunctionName.SQR:
				return [MultiplyCard.create(table, Complex.new(2), bottom.player), FunctionCard.create(table, FunctionName.LOG, top.player)]
			elif bottom.function_name == FunctionName.SQRT:
				return [MultiplyCard.create(table, Complex.new(0.5), bottom.player), FunctionCard.create(table, FunctionName.LOG, top.player)]
			elif bottom.function_name == FunctionName.EXP:
				return [FunctionCard.create(table, FunctionName.X, bottom.player)]
		elif bottom is ValueCard:
			return [ValueCard.create(table, Complex.ln(bottom.value), bottom.player)]
	elif function_name == FunctionName.SQR:
		if bottom is FunctionCard:
			if bottom.function_name == FunctionName.EXP:
				return [FunctionCard.create(table, FunctionName.EXP, bottom.player), MultiplyCard.create(table, Complex.new(2), top.player)]
			elif bottom.function_name == FunctionName.SQRT:
				return [FunctionCard.create(table, FunctionName.ABS, bottom.player)]
		elif bottom is ValueCard:
			return [ValueCard.create(table, Complex.sqr(bottom.value), bottom.player)]
	elif function_name == FunctionName.SQRT:
		if bottom is FunctionCard:
			if bottom.function_name == FunctionName.EXP:
				return [FunctionCard.create(table, FunctionName.EXP, bottom.player), MultiplyCard.create(table, Complex.new(1/2), top.player)]
			elif bottom.function_name == FunctionName.SQR:
				return [FunctionCard.create(table, FunctionName.X, bottom.player)]
		elif bottom is ValueCard:
			return [ValueCard.create(table, Complex.sqrt(bottom.value), bottom.player)]
	elif function_name == FunctionName.ABS:
		if bottom is ValueCard:
			return [ValueCard.create(table, Complex.abs(bottom.value), bottom.player)]
	elif function_name == FunctionName.FLOOR:
		if bottom is ValueCard:
			return [ValueCard.create(table, Complex.floor(bottom.value), bottom.player)]
	elif function_name == FunctionName.SIGN:
		if bottom is ValueCard:
			return [ValueCard.create(table, Complex.sign(bottom.value), bottom.player)]
	elif function_name == FunctionName.SIN:
		if bottom is FunctionCard:
			if bottom.function_name == FunctionName.ADD:
				return [
					FunctionCard.create(table, FunctionName.SIN, bottom.player), FunctionCard.create(table, FunctionName.COS, bottom.player), FunctionCard.create(table, FunctionName.MUL, bottom.player),
					FunctionCard.create(table, FunctionName.SIN, top.player), FunctionCard.create(table, FunctionName.COS, top.player), FunctionCard.create(table, FunctionName.MUL, top.player)
				]
		elif bottom is ValueCard:
			return [ValueCard.create(table, Complex.sin(bottom.value), bottom.player)]
	elif function_name == FunctionName.COS:
		if bottom is FunctionCard:
			if bottom.function_name == FunctionName.ADD:
				return [
					FunctionCard.create(table, FunctionName.COS, bottom.player), FunctionCard.create(table, FunctionName.COS, bottom.player), FunctionCard.create(table, FunctionName.MUL, bottom.player),
					FunctionCard.create(table, FunctionName.SIN, top.player), FunctionCard.create(table, FunctionName.SIN, top.player), FunctionCard.create(table, FunctionName.MUL, top.player)
				]
		elif bottom is ValueCard:
			return [ValueCard.create(table, Complex.cos(bottom.value), bottom.player)]
	elif function_name == FunctionName.TAN:
		if bottom is FunctionCard:
			if bottom.function_name == FunctionName.ADD:
				return [
					FunctionCard.create(table, FunctionName.TAN, bottom.player), FunctionCard.create(table, FunctionName.TAN, bottom.player), FunctionCard.create(table, FunctionName.ADD, bottom.player),
					FunctionCard.create(table, FunctionName.TAN, top.player), FunctionCard.create(table, FunctionName.TAN, top.player), FunctionCard.create(table, FunctionName.ADD, top.player), MultiplyCard.create(table, Complex.new(-1, 0), top.player), ValueCard.create(table, Complex.new(1, 0), top.player)
				]
		elif bottom is ValueCard:
			return [ValueCard.create(table, Complex.cos(bottom.value), bottom.player)]
	elif function_name == FunctionName.ADD:
		if bottom is ValueCard:
			return [PlusCard.create(table, bottom.value, bottom.player)]
	elif function_name == FunctionName.MUL:
		if bottom is ValueCard:
			return [MultiplyCard.create(table, bottom.value, bottom.player)]
	elif function_name == FunctionName.MOD:
		if bottom is ValueCard:
			return [RemainderCard.create(table, bottom.value, bottom.player)]
