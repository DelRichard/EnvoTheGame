extends Node3D

func _ready():
	var enemy = get_node("/root/Main/PumpkinEnemy")
	var npc = get_node("/root/Main/Story_NPC")
	var boss = get_node("/root/Main/ChiliBoss")
	var guard = get_node("/root/Main/Pond_Guard")
	
	enemy.enemy_killed.connect(npc._on_enemy_killed)
	boss.boss_killed.connect(guard._on_boss_killed)
