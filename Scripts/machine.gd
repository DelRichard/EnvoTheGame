extends Node3D

@onready var animation_player: AnimationPlayer = $gear_001/AnimationPlayer

@export var working:= false

func play_animation():
	if working:
		animation_player.play("on")
