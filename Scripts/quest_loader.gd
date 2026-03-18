extends Node

func _ready():
	load_quests()
	
func load_quests():
	var q1 = Quest.new()
	q1.quest_name = "A Friendly Face"
	q1.objectives = [
		"Talk to Larry",
		"Return to base"
	]
	QuestManager.register_quest(q1)
