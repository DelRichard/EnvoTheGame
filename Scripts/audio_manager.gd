extends Node


const BGMUSIC = preload("uid://du7dcrqwond6v")
const BOSS_MUSIC = preload("uid://c8321uftnexka")
const BOSS_LAUGH = preload("uid://dfejd8ievvr7l")

const BOSS_DEATH = preload("uid://cs2xoyrbp3wic")
const HIT_SOUND = preload("uid://dqetueeoelepy")
const REVIVE = preload("uid://befh2q1e6yxf3")
const ENEMY_DEATH_SOUND = preload("uid://cs6dfgxel2a5d")
const DIALOGUE_BLIP = preload("uid://oltds3jid7vo")
const MONSTER_BITE_2 = preload("uid://nj88cq4y7luh")
const MONSTER_BITE = preload("uid://chxbfm4mtytfb")
const MONSTER_CHOMP = preload("uid://236g60cvrp2k")
const PICKUP_1 = preload("uid://07f65vse8304")
const JUMP = preload("uid://beo1dsxjrv7eb")
const PUMPKIN_LAND = preload("uid://d3ijdipm2y1yt")
const WHOOSH = preload("uid://g1kt8lpi6i4a")
const DROP = preload("uid://t7u7120pvvod")

var rng = RandomNumberGenerator.new()


func _ready() -> void:
	play_bg_music()
	rng.randomize()

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

func whoosh_sound():
	play_sound(WHOOSH)

func dialogue_sound():
	play_sound(DIALOGUE_BLIP)
	
func pick_up_sound():
	play_sound(PICKUP_1)

func drop_sound():
	play_sound(DROP)

func boss_bite_sound():
	var random_int = rng.randi_range(1, 3)
	match random_int:
		1: play_sound(MONSTER_CHOMP)
		2: play_sound(MONSTER_BITE)
		3: play_sound(MONSTER_BITE_2)

func pumkin_squash_sound():
	play_sound(PUMPKIN_LAND)

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
