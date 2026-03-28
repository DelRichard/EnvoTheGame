extends Control

@onready var setting: Panel = $Setting
@onready var volume: HSlider = $Setting/Volume
@onready var master_bus = AudioServer.get_bus_index("Master")
@onready var how_to_play_ui: Panel = $"How to play UI"

var mouse_captured = true

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	setting.visible = false
	how_to_play_ui.visible = false
	volume.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	
func _on_start_pressed() -> void:
	AudioManager.dialogue_sound()
	get_tree().change_scene_to_file("res://newMain.tscn")

func _on_settings_pressed() -> void:
	AudioManager.dialogue_sound()
	print("settigs pressed")
	setting.visible = true

func _on_how_to_play_pressed() -> void:
	AudioManager.dialogue_sound()
	how_to_play_ui.visible = true
	


func _on_quit_pressed() -> void:
	AudioManager.dialogue_sound()
	get_tree().quit()


func _on_back_pressed() -> void:
	AudioManager.dialogue_sound()
	_ready()


func _on_volume_value_changed(new_value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(new_value))
	AudioServer.set_bus_mute(master_bus, new_value < 0.01)
