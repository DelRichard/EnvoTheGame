extends Node3D

@onready var animation_player: AnimationPlayer = $gear_001/AnimationPlayer
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D


func turn_on():
	animation_player.play("on")
	audio_stream_player_3d.play()
