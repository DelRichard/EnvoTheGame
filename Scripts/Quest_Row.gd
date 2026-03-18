extends VBoxContainer

@onready var name_label: Label = $Name_Label
@onready var objective_label: Label = $Objective_Label

var pending_name: String = ""
var pending_objective: String = ""

func set_data(labelname: String, objective: String):
	if not is_inside_tree():

		pending_name = labelname
		pending_objective = objective
		return
	name_label.text = labelname
	objective_label.text = objective
	
func _ready():
	if pending_name != "":
		set_data(pending_name, pending_objective)
