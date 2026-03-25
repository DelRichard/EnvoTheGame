extends CharacterBody3D

@onready var interact_area: Area3D = $Interact_Area

var in_dialogue := false
var dialogue_target: Node3D = null

var quest0_completed = false
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
	
func enter_dialogue(target: Node3D) -> void:
	in_dialogue = true
	dialogue_target = target
	
	
func exit_dialogue() -> void:
	in_dialogue = false
	dialogue_target = null
	
func interact():
	var npc_body = self
	if quest0_completed == false:
		quest0_completed = true
		QuestManager.finish_quest("Crazy Introductions")
		
	if quest1_completed == false:
		if quest1_activated == false:
			quest1_activated = true
			QuestManager.start_quest("Teary Fields")
		if InventoryManager.has_item("Wrench"):
			var dialogue = preload("res://Dialogue/Found_Wrench.tres")
			DialogueController.change_npc_dialogue("Gold_Foot", dialogue)
			DialogueManager.start_dialogue(dialogue, npc_body)
			quest1_completed = true
			quest2_activated = true
			QuestManager.finish_quest("Teary Fields")
			QuestManager.start_quest("Green Waters")
			return
		else:
			var dialogue = preload("res://Dialogue/Missing_Wrench.tres")
			DialogueController.change_npc_dialogue("Gold_Foot", dialogue)
			DialogueManager.start_dialogue(dialogue, npc_body)
			return
			
func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		interact()
		
func _on_interact_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = true
		
func _on_interact_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false
