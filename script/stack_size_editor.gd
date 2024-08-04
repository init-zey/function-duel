extends LineEdit

func _on_text_changed(new_text):
	util.change_game_setting("stack_size", int(new_text))
