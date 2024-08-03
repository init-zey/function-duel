extends RichTextLabel

func _on_meta_clicked(meta):
	DisplayServer.clipboard_set(meta)
