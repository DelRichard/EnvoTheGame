extends VBoxContainer

@onready var name_label: Label = $name_label
@onready var objective_label: Label = $objective_label

func set_data(labelname: String, objective: String):
	name_label.text = labelname
	objective_label.text = objective
