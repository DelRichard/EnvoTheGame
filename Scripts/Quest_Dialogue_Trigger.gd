#COPY AND PASTE TEMPLATE FOR EACH NPC
extends Area3D
var quest1_completed = false

@export var npc_id: String = "TEST_NPC"
@export var initial_dialogue: DialogueData

var current_active_dialogue: DialogueData

func _ready():
	add_to_group("npcs")
	update_from_registry()

func update_from_registry():
	pass 

func interact():
	var active_dialogue = DialogueController.get_dialogue_for_npc(npc_id, initial_dialogue)
	DialogueManager.start_dialogue(active_dialogue)

	
func _on_body_entered(body: Node3D) -> void:
	if quest1_completed:
		return
	if body.is_in_group("Player"):
		interact()
		quest1_completed = true
		QuestManager.finish_quest("A Friendly Face")
