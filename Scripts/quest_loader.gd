extends Node

func _ready():
	load_quests()
	
func load_quests():
	var q0 = Quest.new()
	var q1 = Quest.new()
	var q2 = Quest.new()
	var q3 = Quest.new()
	
	q0.quest_name = "Crazy Introductions"
	q0.objectives = ["Talk to Gold Foot"]
	q0.next_quest = "Teary Fields"
	
	q1.quest_name = "Teary Fields"
	q1.objectives = [
		"Find the lost wrench",
		"Return the wrench to gold foot",
	]
	q1.next_quest = "Green Waters"
	
	q2.quest_name = "Green Waters"
	q2.objectives = [
		"Talk to Gold Foot in the village",
		"Find the missing machine parts",
		"Talk to the villager",
		"Defeat the pumpkin veggion",
		"Talk to the villager",
		"Talk to Gold Foot",
	]
	q2.next_quest = "Red Hot Chilli Pepper"
	
	q3.quest_name = "Red Hot Chilli Pepper"
	q3.objectives = [
		"Go to the pond village gate",
		"Defeat the boss",
		"Talk to the guard"
	]
	q3.next_quest = ""
	
	QuestManager.register_quest(q0)
	QuestManager.register_quest(q1)
	QuestManager.register_quest(q2)
	QuestManager.register_quest(q3)
