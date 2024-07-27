extends Control
class_name CardStack

signal assemble_completed()
signal start_deal_completed()
signal cards_inited()
signal start_completed()

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
var names = {
	"function" : deck["function"].keys(),
	"value" : deck["value"].keys(),
	"modify" : deck["modify"].keys()
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
@export var expand : bool = false:
	set(v):
		expand = v
		for index in range(len(cards)):
			var card = cards[index]
			var irate = (float(index) / (len(cards)-1)) - 0.5
			if v:
				card.tween_center_position = self.position + irate * Vector2(card.real_card_size.x * 5, 0)
			else:
				card.tween_center_position = self.position
@export var ribbon_name : String = "":
	set(v):
		ribbon_name = v
		ribbon_text = ribbon_name + "\nWINS!"
@export var ribbon_visible_ratio : float = 0:
	set(v):
		ribbon_visible_ratio = v
		ribbon_label.visible_ratio = v
@export var ribbon_color : Color = Color.WHITE:
	set(v):
		ribbon_color = v
		ribbon_label.modulate = v
@export var ribbon_text : String = "":
	set(v):
		ribbon_text = v
		if ribbon_label:
			ribbon_label.text = "[center][font size=150][wave amp=50.0 freq=5.0 connected=1]" + ribbon_text
@onready var ribbon_label : RichTextLabel = $RibbonLabel
@export var show_ribbon : bool = false:
	set(v):
		if v != show_ribbon:
			var tweener = create_tween()
			tweener.tween_property(ribbon_label, "visible_ratio", 1 if v else 0, 1)
		show_ribbon = v
var start_complete : bool

func assemble(scheme):
	if not network.is_host():
		return#SERVER ONLY
	for category_and_time in scheme:
		var category = category_and_time[0]
		var time = category_and_time[1]
		for t in range(time*2):
			var card_name_idx = extract_random_name_idx(category)
			if card_name_idx == -1:
				continue
			if network.multiplayer.multiplayer_peer:
				add_card.rpc(category, card_name_idx)
			else:
				add_card(category, card_name_idx)
			await get_tree().create_timer(0.1).timeout
	if network.multiplayer.multiplayer_peer:
		assemble_complete.rpc()
	else:
		assemble_complete()

func start():
	assemble(START_SCHEME)
	await assemble_completed
	await get_tree().create_timer(1).timeout
	deal_start()
	await start_deal_completed
	await get_tree().create_timer(1).timeout
	for t in range(1):
		assemble(GAME_SCHEME)
	await assemble_completed
	if network.multiplayer.multiplayer_peer:
		complete_start.rpc()
	else:
		complete_start()

@rpc('call_local')
func deal(cpos=null):
	for t in range(2):
		var card = cards[-1]
		var player = even if t%2==0 else odd
		cards.resize(len(cards) - 1)
		card.send_to(player, cpos)
		card.tween_revolve = 0
	util.play_sound(preload("res://asset/sound/card_appear.mp3"))

func extract_random_name_idx(category) -> int:
	var sum = 0
	var pool = deck_remain[category]
	for card_name in pool:
		sum += pool[card_name]
	var ri = randi()%sum
	for card_name in pool:
		ri -= pool[card_name]
		if ri < 0:
			pool[card_name] -= 1
			return names[category].find(card_name)#prevent key not found when RPC
	return -1

func deal_start():
	if not network.is_host():
		return
	var csize = CardStack.find_proper_size(6)
	for t in range(6):
		var cpos = Vector2(t % csize.x, t / csize.x) - Vector2(csize - Vector2i(1, 1))*0.5
		if network.multiplayer.multiplayer_peer:
			deal.rpc(cpos)
		else:
			deal(cpos)
		await get_tree().create_timer(0.1).timeout
	start_deal_completed.emit()
	
@rpc('call_local')
func add_card(category, card_name_idx):
	util.play_sound(preload("res://asset/sound/card_appear.mp3"), 0, 2, -15-card_name_idx)
	var new_card = null
	var card_name = names[category][card_name_idx]
	if category == "function":
		new_card = FunctionCard.create(table, card_name, null)
	elif category == "value":
		new_card = ValueCard.create(table, card_name, null)
	elif category == "modify":
		new_card = ModifyCard.create(table, card_name, null)
	table.add_child(new_card)
	cards.append(new_card)
	new_card.center_position = position
	new_card.revolve = PI/2
	new_card.tween_revolve = PI

@rpc('call_local')
func assemble_complete():
	assemble_completed.emit()

@rpc('call_local')
func complete_start():
	start_complete = true
	start_completed.emit()
