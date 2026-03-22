extends CanvasLayer

@onready var panel: Panel = $BackgroundPanel
@onready var text_label: Label = $BackgroundPanel/Label

var current_dialogue: DialogueData
var line_index: int = 0
var is_active: bool = false
var active_npc: Node = null

func _ready():
	panel.hide()
	set_process_input(false)

func start_dialogue(data: DialogueData, npc: Node = null):
	if is_active:
		return
	if not data or data.lines.is_empty():
		return
	
	current_dialogue = data
	line_index = 0
	is_active = true
	
	var player = get_tree().get_first_node_in_group("Player")
	
	get_tree().call_group("Player", "enter_dialogue")
	get_tree().call_group("Player", "set_physics_process", false)
	
	if npc:
		active_npc = npc
		npc.enter_dialogue(player)
	panel.show()
	set_process_input(true)
	display_line()

func display_line():
	if line_index < current_dialogue.lines.size():
		text_label.text = current_dialogue.lines[line_index]
	else:
		finish_dialogue()
func finish_dialogue():
	is_active = false
	panel.hide()
	set_process_input(false)
	
	get_tree().call_group("Player", "exit_dialogue")
	get_tree().call_group("Player", "set_physics_process", true)
	
	if active_npc:
		active_npc.exit_dialogue()
		active_npc = null
		
func _input(event):
	if is_active and event.is_action_pressed("interact"):
		line_index += 1
		display_line()
