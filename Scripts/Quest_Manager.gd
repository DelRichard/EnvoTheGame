extends Node

signal quest_started(quest_name)
signal quest_updated(quest_name, objective)
signal quest_completed(quest_name)

var quests: Dictionary = {}

func register_quest(quest: Quest):
	if quest == null:
		push_error("Tried to register null quest")
		return
		
	if quests.has(quest.quest_name):
		push_warning("Quest already registered: " + quest.quest_name)
		
	quests[quest.quest_name] = quest
	print("Registered quest:", quest.quest_name)
	
func start_quest(quest_name: String):
	var quest = quests.get(quest_name)
	
	if quest == null:
		push_error("Quest not found: " + quest_name)
		return
		
	if quest.state != Quest.QuestState.NOT_STARTED:
		return
	quest.state = Quest.QuestState.STARTED
	quest.current_objective_index = 0
	
	print("Quest Started:", quest_name)
	emit_signal("quest_started", quest_name)
	
func update_objective(quest_name: String):
	var quest = quests.get(quest_name)
	
	if quest == null:
		push_error("Quest not found: " + quest_name)
		return
		
	if quest.state != Quest.QuestState.STARTED:
		return
		
	quest.current_objective_index += 1
	if quest.current_objective_index >= quest.objectives.size():
		finish_quest(quest_name)
	else:
		var obj = quest.get_current_objective()
		print("Objective Updated")
		emit_signal("quest_updated", quest_name, obj)
		
func set_objective(quest_name: String, new_text: String):
	var quest = quests.get(quest_name)
	if quest == null:
		push_error("Quest not found: " + quest_name)
		return
	quest.objectives[quest.current_objective_index] = new_text
	emit_signal("quest_updated", quest_name, new_text)
	
func finish_quest(quest_name: String):
	var quest = quests.get(quest_name)
	
	if quest == null:
		push_error("Quest not found: " + quest_name)
		return
		
	if quest.state != Quest.QuestState.STARTED:
		return
		
	quest.state = Quest.QuestState.COMPLETED
	print("Quest Completed:", quest_name)
	emit_signal("quest_completed", quest_name)
	trigger_quest_event(quest_name)
	
func trigger_quest_event(quest_name: String):
	match quest_name:
		"Crazy Introductions":
			print("Crazy Introductions Quest Completed")
		"Teary Fields":
			print("Teary Fields Quest Completed")
		"Green Waters":
			print("Green Waters Quest Completed")
		"Red Hot Chilli Pepper":
			print("Red Hot Chilli Pepper Quest Completed")
