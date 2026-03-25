extends Sprite3D

@export var item_name: String = "MachinePart"
@export var amount: int = 1

var player_in_range := false

func interact():
	if not player_in_range: 
		return
	InventoryManager.add_item(item_name, amount)
	if item_name == "MachinePart":
		var count = InventoryManager.get_item_count("MachinePart")
		var q2 = QuestManager.quests.get("Green Waters")
		
		if q2 and q2.state == Quest.QuestState.STARTED:
			if count >= 2:
				QuestManager.set_objective_index("Green Waters", 5)
	queue_free()
	
func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		interact()
		
func _on_pick_up_range_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"): 
		player_in_range = true
		
func _on_pick_up_range_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"): 
		player_in_range = false
