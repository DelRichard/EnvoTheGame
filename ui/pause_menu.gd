extends Control

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var setting: Panel = $Setting
@onready var volume: HSlider = $Setting/Volume
@onready var master_bus = AudioServer.get_bus_index("Master")



func _ready():
	# Hide the pause menu initially
	hide()
	setting.visible = false

func _input(event):
	# Toggle pause when pressing ESC
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused
	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _on_resume_button_pressed() -> void:
	toggle_pause()


func _on_settings_button_pressed() -> void:
	print("settigs pressed")
	setting.visible = true


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	setting.visible = false


func _on_volume_value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(new_value))
	AudioServer.set_bus_mute(master_bus, new_value < 0.01)
