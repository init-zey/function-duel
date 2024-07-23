@tool
extends Node2D
class_name Drawer

func _ready():
	queue_redraw()

func _draw():
	draw_circle(Vector2(), 16, Color.ORANGE)
