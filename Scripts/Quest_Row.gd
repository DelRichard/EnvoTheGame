extends VBoxContainer

@onready var name_label: Label = $Name_Label
@onready var objective_label: Label = $Objective_Label

func set_data(labelname: String, objective: String):
	name_label.text = labelname
	objective_label.text = objective
