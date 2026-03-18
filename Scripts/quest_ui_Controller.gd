extends CanvasLayer


@onready var quest_list: VBoxContainer = $ScrollContainer/QuestList
var quest_item_scene = preload("res://scenes/quest_row.tscn")

var active_items = {}

func _ready():
	QuestManager.connect("quest_started", _on_quest_started)
	QuestManager.connect("quest_updated", _on_quest_updated)
	QuestManager.connect("quest_completed", _on_quest_completed)
	
	for quest_name in QuestManager.quests.keys():
		var quest = QuestManager.quests[quest_name]
		if quest.state == Quest.QuestState.STARTED:
			_on_quest_started(quest_name)
			
func _on_quest_started(quest_name):
	var quest = QuestManager.quests.get(quest_name)
	if quest == null:
		return
	if quest_list == null:
		call_deferred("_on_quest_started", quest_name)
		return
	var item = quest_item_scene.instantiate()
	quest_list.add_child(item) 
	item.set_data(quest_name, quest.get_current_objective())
	active_items[quest_name] = item
	
func _on_quest_updated(quest_name, objective):
	if active_items.has(quest_name):
		active_items[quest_name].set_data(quest_name, objective)
		
func _on_quest_completed(quest_name):
	if active_items.has(quest_name):
		active_items[quest_name].queue_free()
		active_items.erase(quest_name)
