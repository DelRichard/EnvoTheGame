extends Node

signal quest_started(quest_name)
signal quest_updated(quest_name, objective)
signal quest_completed(quest_name)

var quests: Dictionary = {}

func register_quest(quest: Quest):
	quests[quest.quest_name] = quest
	
func start_quest(quest_name: String):
	var quest = quests.get(quest_name)
	if quest and quest.state == Quest.QuestState.NOT_STARTED:
		quest.state = Quest.QuestState.STARTED
		quest.current_objective_index = 0
		emit_signal("quest_started", quest_name)
		
func update_objective(quest_name: String):
	var quest = quests.get(quest_name)
	if quest and quest.state == Quest.QuestState.STARTED:
		quest.current_objective_index += 1
		if quest.current_objective_index >= quest.objectives.size():
			finish_quest(quest_name)
		else:
			emit_signal("quest_updated", quest_name, quest.get_current_objective())
			
func set_objective_index(quest_name: String, index: int):
	var quest = quests.get(quest_name)
	if quest and quest.state == Quest.QuestState.STARTED:
		quest.current_objective_index = index
		emit_signal("quest_updated", quest_name, quest.get_current_objective())
		
func finish_quest(quest_name: String):
	var quest = quests.get(quest_name)
	if quest and quest.state == Quest.QuestState.STARTED:
		quest.state = Quest.QuestState.COMPLETED
		emit_signal("quest_completed", quest_name)
		if quest.next_quest != "":
			start_quest(quest.next_quest)
