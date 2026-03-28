extends Label

@export var scroll_speed := 200.0

func _ready():
	position.y = get_viewport_rect().size.y

func _process(delta):
	position.y -= scroll_speed * delta
	if position.y + size.y < 0:
		get_tree().change_scene_to_file("res://newMain.tscn")
