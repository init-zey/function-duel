extends MarginContainer

@export var volume_slider : HSlider
@export var ui_scale_slider : HSlider
@export var stack_size_editor : LineEdit
@export var lang_selector : OptionButton

func _ready():
	util.game_setting_loaded.connect(self._on_game_setting_loaded)

func _on_game_setting_loaded(key, value):
	match key:
		"volume":
			volume_slider.set_value_no_signal(value)
		"ui_scale":
			ui_scale_slider.set_value_no_signal(log(value)/log(2))
		"stack_size":
			stack_size_editor.text = str(value)
		"lang_index":
			lang_selector.select(value)

func _on_volume_setter_drag_ended(value_changed):
	util.change_game_setting("volume", volume_slider.value)
	$"../ButtonSound".play()

func _on_ui_scale_setter_drag_started():
	util.change_game_setting("ui_scale", pow(2, ui_scale_slider.value))

func _on_stack_size_editor_text_changed(new_text):
	var new_size = clamp(int(new_text), 1, 16)
	if new_text != "":
		stack_size_editor.text = str(new_size)
		stack_size_editor.select_all()
	util.change_game_setting("stack_size", new_size)

func _on_lang_selector_item_selected(index):
	util.change_game_setting("lang_index", index)
