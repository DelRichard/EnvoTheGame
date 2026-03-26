extends Node3D

@onready var interact_icon: Sprite3D = get_node_or_null("Icon")

func toggle_visibility():
	if interact_icon == null:
		print("WARNING: Icon missing on ", get_path())
		return
		
	interact_icon.visible = !interact_icon.visible
