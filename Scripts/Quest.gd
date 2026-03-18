extends Resource
class_name Quest

enum QuestState {
	NOT_STARTED,
	STARTED,
	COMPLETED
}

@export var quest_name: String
@export var objectives: Array = []

var current_objective_index: int = 0
var state: QuestState = QuestState.NOT_STARTED

func get_current_objective() -> String:
	if current_objective_index < objectives.size():
		return objectives[current_objective_index]
	return ""
