extends Node

func _ready():
	load_quests()
	
func load_quests():
	var q0 = Quest.new()
	var q1 = Quest.new()
	var q2 = Quest.new()
	var q3 = Quest.new()
	
	q0.quest_name = "Crazy Introductions"
	q0.objectives = [
		"Talk to Gold Foot",
	]
	
	q1.quest_name = "Teary Fields"
	q1.objectives = [
		"Find the lost wrench",
		"Talk to Gold Foot",
	]
	
	q2.quest_name = "Green Waters"
	q2.objectives = [
		"Find the missing machine parts",
		"Talk to Gold Foot",
		"Investigate the valley",
		"Defeat the pumpkin veggions",
		"Talk to the villager",
		"Talk to Gold Foot",
	]
	
	q3.quest_name = "Red Hot Chilli Pepper"
	q3.objectives = [
		"Talk to the ogre",
		"Go to the pond village gate",
		"Defeat the boss",
	]
	
	QuestManager.register_quest(q0)
	QuestManager.register_quest(q1)
	QuestManager.register_quest(q2)
	QuestManager.register_quest(q3)
