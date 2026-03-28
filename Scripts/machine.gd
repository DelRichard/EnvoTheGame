extends Node3D

@onready var animation_player: AnimationPlayer = $gear_001/AnimationPlayer
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@export var working:= false

func play_animation():
	if working:
		animation_player.play("on")
		audio_stream_player_3d.play()
