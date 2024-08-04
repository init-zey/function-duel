extends Node

signal game_setting_loaded(key, value)

var config_file : ConfigFile = ConfigFile.new()
var loaded : bool = false

const math_font : Font = preload("res://asset/font/ThaleahFatWithAGoodI.pfb")

func _ready():
	await get_tree().process_frame
	load_game_setting()
	
	var theme = preload("res://asset/user_interface/function_duel_theme.tres")
	var keys = FunctionCard.name_texture_dict.keys()
	var rand_key = keys[randi()%len(keys)]
	var random_icon = FunctionCard.name_texture_dict[rand_key]
	theme["HSlider/icons/grabber"] = random_icon
	theme["HSlider/icons/grabber_disabled"] = random_icon
	theme["HSlider/icons/grabber_highlight"] = random_icon

func play_sound(audio_stream, start_time=0, pitch_scale=1, volume_db=0):
	var audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	audio_stream_player.stream = audio_stream
	audio_stream_player.pitch_scale = pitch_scale
	audio_stream_player.volume_db = volume_db
	audio_stream_player.play(start_time)
	await audio_stream_player.finished
	audio_stream_player.queue_free()

func change_game_setting(key, value):
	config_file.set_value("game_setting", key, value)
	apply_game_setting(key, value)

func apply_game_setting(key, value):
	if key == "volume":
		AudioServer.set_bus_volume_db(0, -50 * (1-value))
	elif key == "ui_scale":
		get_parent().get_node("Game")._on_viewport_size_changed()

func save_game_setting():
	config_file.save("user://config.ini")
	
func load_game_setting():
	var err = config_file.load("user://config.ini")
	if err == OK:
		for key in config_file.get_section_keys("game_setting"):
			var value = config_file.get_value("game_setting", key)
			game_setting_loaded.emit(key, value)
			apply_game_setting(key, value)
	else:
		change_game_setting("volume", 1)
		change_game_setting("ui_scale", 1)
		change_game_setting("stack_size", 3)
		change_game_setting("lang_index", 0)
	loaded = true

func get_game_setting(key):
	return config_file.get_value("game_setting", key)

func _exit_tree():
	save_game_setting()
