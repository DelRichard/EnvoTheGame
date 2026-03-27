extends CharacterBody3D

@onready var interact_area: Area3D = $Interact_Area
@onready var interact_icon = get_node("/root/Main/Player/Interact_Icon")
@export var npc_id: String = "Gold_Foot"
@export var initial_dialogue: DialogueData


var player_in_range := false
var has_talked := false
var in_dialogue := false
var dialogue_target: Node3D = null
var found_two_played := false

func _ready():
	add_to_group("npcs")


func enter_dialogue(target: Node3D) -> void:
	in_dialogue = true
	dialogue_target = target
	
func exit_dialogue() -> void:
	in_dialogue = false
	dialogue_target = null
	
func interact():
	if DialogueManager.is_active:
		return
		
	var npc_body = self
	var q1 = QuestManager.quests.get("Teary Fields")
	var q2 = QuestManager.quests.get("Green Waters")
	var q3 = QuestManager.quests.get("Red Hot Chilli Pepper")
	
	if (q3 and q3.state == Quest.QuestState.STARTED) or (q2 and q2.state == Quest.QuestState.COMPLETED):
		var dialogue = preload("res://Dialogue/Repeat goodluck.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		return
	
	#Initial Dialogue
	if not has_talked:
		has_talked = true
		QuestManager.finish_quest("Crazy Introductions")
		QuestManager.start_quest("Teary Fields")
		if InventoryManager.has_item("Wrench"):
			QuestManager.set_objective_index("Teary Fields", 1)
		DialogueManager.start_dialogue(initial_dialogue, npc_body)
		return
		
	#Quest 1
	if q1 and q1.state == Quest.QuestState.STARTED:
		if InventoryManager.has_item("Wrench"):
			var dialogue = preload("res://Dialogue/Found_Wrench.tres")
			DialogueManager.start_dialogue(dialogue, npc_body)
			QuestManager.finish_quest("Teary Fields")
			print("Unlock next area and move gold foot")
			return 
		else:
			var dialogue = preload("res://Dialogue/Missing_Wrench.tres")
			DialogueManager.start_dialogue(dialogue, npc_body)
			return
			
	#Quest 2
	if q2 and q2.state == Quest.QuestState.STARTED:
		var parts = InventoryManager.get_item_count("MachinePart")
		
		if q2.current_objective_index == 0:
			var dialogue = preload("res://Dialogue/Stolen_Parts.tres")
			DialogueManager.start_dialogue(dialogue, npc_body)
			QuestManager.set_objective_index("Green Waters", 1)
			return
			
		if parts >= 2 and not found_two_played:
			var dialogue = preload("res://Dialogue/Found_Two.tres")
			DialogueManager.start_dialogue(dialogue, npc_body)
			found_two_played = true
			QuestManager.set_objective_index("Green Waters", 2)
			print("Unlock next area and move gold foot")
			return
			
		if found_two_played and parts < 3:
			var dialogue = preload("res://Dialogue/Find_Villagers.tres")
			DialogueManager.start_dialogue(dialogue, npc_body)
			return
		
		# When player finds three parts
		if parts >= 3:
			var dialogue = preload("res://Dialogue/Final_Found.tres")
			DialogueManager.start_dialogue(dialogue, npc_body)
			QuestManager.finish_quest("Green Waters")
			InventoryManager.add_item("water", 1)
			print("Unlock next area")
			return
		
		var dialogue = preload("res://Dialogue/Missing_Parts.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		return
		
	DialogueManager.start_dialogue(initial_dialogue, npc_body)
	
func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		interact()
		
func _on_interact_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		interact_icon.toggle_visibility()
		player_in_range = true
	
func _on_interact_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		interact_icon.toggle_visibility()
		player_in_range = false
