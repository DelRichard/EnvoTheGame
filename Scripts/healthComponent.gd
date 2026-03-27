class_name HealthComponent extends Node

signal health_changed
signal died
signal hit(from_position)

@export var max_health := 100.0
var current_health := 0.0

var invincible := false 


func _ready() -> void:
	current_health = max_health
	_emit()

func damage(amount: float, from_position: Vector3, knockback: float = 0.0) -> void:
	if invincible:
		return
	
	invincible = true
	
	current_health = clamp(current_health - amount, 0.0, max_health)
	_emit()
	hit.emit(from_position, knockback)
	
	if current_health == 0.0:
		died.emit()
	
	await get_tree().create_timer(0.5).timeout #so that the character can’t be hit multiple times instantly
	invincible = false

func heal(amount: float) -> void:
	current_health = clamp(current_health + amount, 0.0, max_health)
	_emit()

func reset_health() -> void:
	current_health = max_health
	invincible = false
	_emit()


func _emit() -> void:
	health_changed.emit(current_health, max_health)
	print("HP: %d / %d" % [current_health,max_health])
