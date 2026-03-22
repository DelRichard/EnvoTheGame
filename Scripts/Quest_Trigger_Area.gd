extends Area3D
var quest1_completed = false

func _on_body_entered(body: Node3D) -> void:
	if quest1_completed:
		return
	if body.is_in_group("Player"):
		quest1_completed = true
		QuestManager.finish_quest("A Friendly Face")
