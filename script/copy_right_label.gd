extends RichTextLabel

func _ready():
	self.text = "[right]CC-BY-SA 3.0\n@anti-zey\n" + ProjectSettings["application/config/version"]
