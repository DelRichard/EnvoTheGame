extends Node


const BGMUSIC = preload("uid://du7dcrqwond6v")
const BOSS_MUSIC = preload("uid://c8321uftnexka")
const BOSS_LAUGH = preload("uid://dfejd8ievvr7l")

const BOSS_DEATH = preload("uid://cs2xoyrbp3wic")
const HIT_SOUND = preload("uid://dqetueeoelepy")
const JUMP = preload("uid://2fguwgmyg1jy")
const REVIVE = preload("uid://befh2q1e6yxf3")
const ENEMY_DEATH_SOUND = preload("uid://cs6dfgxel2a5d")

func _ready() -> void:
	play_bg_music()

func play_sound(sound: AudioStreamWAV):
	$SFX.stream = sound
	$SFX.play()

func play_bg_music():
	$Music.stream = null
	$Music.stop()
	$Music.stream = BGMUSIC
	$Music.play()

func play_boss_music():
	$Music.stream = null
	$Music.stop()
	$Music.stream = BOSS_MUSIC
	$Music.play()

func boss_laugh_sound():
	play_sound(BOSS_LAUGH)
	
func jump_sound():
	play_sound(JUMP)

func revive_sound():
	play_sound(REVIVE)

func death_sound():
	play_sound(ENEMY_DEATH_SOUND)

func boss_death_sound():
	play_sound(BOSS_DEATH)

func hit_sound():
	play_sound(HIT_SOUND)

func stop_sound():
	$SFX.stream = null

func stop_music():
	$Music.stream = null
