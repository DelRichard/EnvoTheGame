extends Area3D
var quest1_completed = false
var quest2_completed = false
var quest3_completed = false

var quest1_activated = false
var quest2_activated = false
var quest3_activated = false

@export var npc_id: String = "Gold_Foot"
@export var initial_dialogue: DialogueData

var current_active_dialogue: DialogueData
var player_in_range := false

func _ready():
	add_to_group("npcs")
	update_from_registry()

func update_from_registry():
	pass 

func interact():
	var npc_body = get_parent() as CharacterBody3D
	if not npc_body:
		return
		
	if quest1_completed == false:
		if quest1_activated == false:
			QuestManager.start_quest("Teary Fields")
			var active_dialogue = DialogueController.get_dialogue_for_npc(npc_id, initial_dialogue)
			DialogueManager.start_dialogue(active_dialogue, npc_body)
		else:
			if InventoryManager.search_inventory("wrench") == true:
				
				#current_active_dialogue = (preload("FOUND WRENCH DIALOGUE"))
				DialogueController.change_npc_dialogue("Gold_Foot", current_active_dialogue)
				
				quest1_completed = true
				quest2_activated = true
				
				QuestManager.finish_quest("Teary Fields")
				QuestManager.start_quest("Green Waters")
				#WALK TO LAKE
			else:
				#CHANGE CURRENT
				current_active_dialogue = (preload("res://Dialogue/Default_Dialogue.tres"))
				DialogueController.change_npc_dialogue("Gold_Foot", current_active_dialogue)
	else:
		return
		
	if quest2_completed == false:
		if quest2_activated == false:
			#current_active_dialogue = (preload("FOUND WRENCH DIALOGUE"))
			var active_dialogue = DialogueController.get_dialogue_for_npc(npc_id, current_active_dialogue)
			DialogueManager.start_dialogue(active_dialogue, npc_body)
		else:
			pass
			
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
		
func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		interact()
