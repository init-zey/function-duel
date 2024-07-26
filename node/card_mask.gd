@tool
extends ColorRect
class_name CardMask

var center_position : Vector2:
	set(v):
		center_position = v
		position = v - size/2

func _ready():
	material = ShaderMaterial.new()
	material.shader = preload("res://shader/card_mask.gdshader")
	color = Color.TRANSPARENT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
