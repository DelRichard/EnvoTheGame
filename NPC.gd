extends CharacterBody3D

@onready var interact_area: Area3D = $Interact_Area
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var interact_icon = get_node("/root/Main/Player/Interact_Icon")

@export var npc_id: String = "Jimmy"
@export var initial_dialogue: DialogueData

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var in_dialogue := false
var dialogue_target: Node3D = null
var player_in_range := false
var pumpkin_killed := false
var machine_part_given := false
var post_reward_dialogue_played := false

func _physics_process(delta: float) -> void:
		if not is_on_floor():
			velocity.y -= gravity * delta
		
func _ready():
	animated_sprite_3d.play("idle")
	add_to_group("npcs")
	
func enter_dialogue(target: Node3D) -> void:
	in_dialogue = true
	dialogue_target = target
	
func exit_dialogue() -> void:
	in_dialogue = false
	dialogue_target = null
	
func interact():
	var npc_body = self
	var q2 = QuestManager.quests.get("Green Waters")
	if machine_part_given:
		var dialogue = preload("res://Dialogue/Pumpkin_Loop.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		return
		
	if pumpkin_killed:
		var dialogue = preload("res://Dialogue/Pumpkin_killed.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		InventoryManager.add_item("MachinePart", 1)
		machine_part_given = true
		QuestManager.set_objective_index("Green Waters", 5)
		return
		
	elif q2 and q2.state == Quest.QuestState.STARTED:
		QuestManager.set_objective_index("Green Waters", 3)
		var dialogue = preload("res://Dialogue/Please_Help.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		
	else:
		var dialogue = preload("res://Dialogue/Default_Dialogue.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
	
func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		interact()
		
func _on_enemy_killed(enemy_id: String) -> void:
	if enemy_id == "pumpkin":
		pumpkin_killed = true
		
		var q2 = QuestManager.quests.get("Green Waters")
		if q2:
			QuestManager.set_objective_index("Green Waters", 4)
			
func _on_interact_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		interact_icon.toggle_visibility()
		player_in_range = true
		
func _on_interact_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		interact_icon.toggle_visibility()
		player_in_range = false
