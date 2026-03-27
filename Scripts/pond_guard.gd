extends CharacterBody3D

@onready var interact_area: Area3D = $Interact_Area
@onready var interact_icon = get_node("/root/Main/Player/Interact_Icon")

@export var npc_id: String = "Guard"
@export var initial_dialogue: DialogueData
@export var boss_spawner: Node

var in_dialogue := false
var dialogue_target: Node3D = null
var player_in_range := false
var chilli_killed := false
var chilli_dialogue_played := false 
var go_away_played := false
var should_spawn_boss := false

func _ready():
	add_to_group("npcs")
	
	if not DialogueManager.dialogue_finished.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
func enter_dialogue(target: Node3D) -> void:
	in_dialogue = true
	dialogue_target = target
	
func exit_dialogue() -> void:
	in_dialogue = false
	dialogue_target = null
	
func interact():
	var npc_body = self
	var q3 = QuestManager.quests.get("Red Hot Chilli Pepper")
	
	if chilli_killed and not chilli_dialogue_played:
		var dialogue = preload("res://Dialogue/chilli_killed.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		QuestManager.finish_quest("Red Hot Chilli Pepper")
		chilli_dialogue_played = true  
		
	elif chilli_killed and chilli_dialogue_played:
		var dialogue = preload("res://Dialogue/Guard_Loop.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		
	elif q3 and q3.state == Quest.QuestState.STARTED and not go_away_played:
		QuestManager.set_objective_index("Red Hot Chilli Pepper", 1)
		var dialogue = preload("res://Dialogue/Go_Away.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		go_away_played = true
		should_spawn_boss = true
		

			
	elif q3 and q3.state == Quest.QuestState.STARTED and go_away_played:
		var dialogue = preload("res://Dialogue/Guard_Loop.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		
	else:
		var dialogue = preload("res://Dialogue/Default_Dialogue.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
	
func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		interact()
		
func _on_boss_killed(boss_id: String) -> void:
	if boss_id == "boss":
		chilli_killed = true
		
		var q3 = QuestManager.quests.get("Red Hot Chilli Pepper")
		if q3:
			QuestManager.set_objective_index("Red Hot Chilli Pepper", 2)
			
func _on_dialogue_finished():
	if should_spawn_boss and boss_spawner:
		var boss = boss_spawner.spawn_boss()
		
		if boss:
			boss.boss_killed.connect(_on_boss_killed)
		
		should_spawn_boss = false
		
func _on_interact_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		interact_icon.toggle_visibility()
		player_in_range = true
		
func _on_interact_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		interact_icon.toggle_visibility()
		player_in_range = false
