extends Area3D
var quest1_completed = false

@export var npc_id: String = "TEST_NPC"
@export var initial_dialogue: DialogueData

var current_active_dialogue: DialogueData
var player_in_range := false

func _ready():
	add_to_group("npcs")
	update_from_registry()

func update_from_registry():
	pass 

func interact():
	if quest1_completed:
		return
	
	var npc_body = get_parent() as CharacterBody3D
	if not npc_body:
		return
	
	var active_dialogue = DialogueController.get_dialogue_for_npc(npc_id, initial_dialogue)
	DialogueManager.start_dialogue(active_dialogue, npc_body)
	
	quest1_completed = true
	QuestManager.finish_quest("A Friendly Face")
	
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		
func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		interact()
