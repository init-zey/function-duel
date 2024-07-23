extends Control
class_name CardStack

static func find_proper_size(n:int)->Vector2i:
	var i:int=floor(sqrt(n))
	var l:int=pow(i,2)
	var h:int=pow(i+1,2)
	if n-l<h-n:
		h=l
	var x:int=h-1
	while x>0&&n%x!=0:
		x-=1
	return Vector2i(x, n/x)

var deck : Dictionary = {
	"function" : {
		FunctionCard.FunctionName.X : 3,
		FunctionCard.FunctionName.EXP : 3,
		FunctionCard.FunctionName.REVERSE : 3,
		FunctionCard.FunctionName.SQR : 3,
		FunctionCard.FunctionName.SQRT : 3,
		FunctionCard.FunctionName.ABS : 3,
		FunctionCard.FunctionName.ADD : 3,
		FunctionCard.FunctionName.MUL : 3,
		FunctionCard.FunctionName.MOD : 3,
		FunctionCard.FunctionName.SIN : 3,
		FunctionCard.FunctionName.COS : 3,
		FunctionCard.FunctionName.TAN : 3,
		FunctionCard.FunctionName.SIGN : 3,
		FunctionCard.FunctionName.FLOOR : 3,
	},
	"value" : {
		Complex.new(1, 0) :10,
		Complex.new(0, 0) : 10,
		Complex.new(-1, 0) : 10,
		Complex.new(0, 1) : 10,
	},
	"modify" : {
		"d/dx" : 50,
	}
}

const START_SCHEME : Array = [
	["function", 3],
	["value", 2],
	["modify", 1],
]

const GAME_SCHEME : Array = [
	["function", 1],
	["value", 1],
	["modify", 1],
]

@export var table : Table
@export var even : Player
@export var odd : Player
var cards : Array
var deck_remain : Dictionary = deck
@export var expand : bool

func assemble(scheme):
	for category_and_time in scheme:
		var category = category_and_time[0]
		var time = category_and_time[1]
		for t in range(time*2):
			var card_name = extract_random_name(category)
			if card_name == null:
				continue
			var new_card = null
			if category == "function":
				new_card = FunctionCard.create(table, card_name, null)
			elif category == "value":
				new_card = ValueCard.create(table, card_name, null)
			elif category == "modify":
				new_card = ModifyCard.create(table, card_name, null)
			table.add_child(new_card)
			new_card.position = position
			cards.append(new_card)
			new_card.revolve = PI/2
			new_card.tween_revolve = PI

func _ready():
	await get_tree().process_frame
	assemble_and_deal_start()
	for t in range(1):
		assemble(GAME_SCHEME)

func _process(delta):
	for index in range(len(cards)):
		var card = cards[index]
		var irate = (float(index) / (len(cards)-1)) - 0.5
		card.tween_center_position = position + irate * (Vector2(card.real_card_size.x * 5, 0) if expand else Vector2())

func deal(cpos=null):
	for t in range(2):
		var card = cards[-1]
		var player = even if t%2==0 else odd
		cards.resize(len(cards) - 1)
		card.send_to(player, cpos)
		card.tween_revolve = 0

func extract_random_name(category):
	var sum = 0
	var pool = deck_remain[category]
	for card_name in pool:
		sum += pool[card_name]
	var ri = randi()%sum
	for card_name in pool:
		ri -= pool[card_name]
		if ri < 0:
			pool[card_name] -= 1
			return card_name

func assemble_and_deal_start():
	assemble(START_SCHEME)
	await get_tree().create_timer(0.2).timeout
	var csize = CardStack.find_proper_size(6)
	for t in range(6):
		var cpos = Vector2(t % csize.x, t / csize.x) - Vector2(csize - Vector2i(1, 1))*0.5
		deal(cpos)
