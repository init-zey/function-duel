extends Node

const math_font : Font = preload("res://asset/font/ThaleahFatWithAGoodI.pfb")

func play_sound(audio_stream, start_time=0, pitch_scale=1):
	var audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	audio_stream_player.stream = audio_stream
	audio_stream_player.pitch_scale = pitch_scale
	audio_stream_player.play(start_time)
	await audio_stream_player.finished
	audio_stream_player.queue_free()
