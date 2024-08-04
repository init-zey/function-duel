extends OptionButton

func _on_item_selected(index):
	util.change_game_setting("lang_index", index)
