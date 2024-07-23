extends Button
func _process(delta):
	text = "Your IP: " + IP.get_local_addresses()[9] + "(click to copy)"
func _pressed():
	DisplayServer.clipboard_set(IP.get_local_addresses()[9])
