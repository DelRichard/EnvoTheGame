extends Node

var npc_dialogue_registry: Dictionary = {}

func change_npc_dialogue(npc_id: String, new_dialogue: DialogueData):
	npc_dialogue_registry[npc_id] = new_dialogue
	get_tree().call_group("npcs", "update_from_registry")
	
func get_dialogue_for_npc(npc_id: String, default_dialogue: DialogueData) -> DialogueData:
	if npc_dialogue_registry.has(npc_id):
		return npc_dialogue_registry[npc_id]
	return default_dialogue
