extends Sprite3D

@export var item_name: String = "Item"
@export var amount: int = 1

@export var hover_amplitude: float = 0.25
@export var hover_speed: float = 2.0

var player_in_range := false
var base_position: Vector3
var time := 0.0

func _ready():
	base_position = position
	
func _process(delta):
	time += delta
	position.y = base_position.y + sin(time * hover_speed) * hover_amplitude
	
func interact():
	if not player_in_range:
		return
	InventoryManager.add_item(item_name, amount)
	var quest = QuestManager.quests.get("Teary Fields")
	if quest:
		if quest.state == Quest.QuestState.STARTED:
			QuestManager.update_objective("Teary Fields")
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
