extends CanvasLayer

@onready var quest_list: VBoxContainer = $ScrollContainer/quest_list


var quest_item_scene = preload("res://scenes/quest_row.tscn")

var active_items = {}

func _ready():
	QuestManager.connect("quest_started", _on_quest_started)
	QuestManager.connect("quest_updated", _on_quest_updated)
	QuestManager.connect("quest_completed", _on_quest_completed)


func _on_quest_started(name):
	var quest = QuestManager.quests[name]

	var item = quest_item_scene.instantiate()
	item.set_data(name, quest.get_current_objective())

	quest_list.add_child(item)
	active_items[name] = item


func _on_quest_updated(name, objective):
	if active_items.has(name):
		active_items[name].set_data(name, objective)


func _on_quest_completed(name):
	if active_items.has(name):
		active_items[name].queue_free()
		active_items.erase(name)
