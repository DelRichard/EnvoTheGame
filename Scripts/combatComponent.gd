class_name CombatComponent extends Node

@onready var health_component: HealthComponent = $"../HealthComponent"
@onready var enemy: CharacterBody3D = $".."
@onready var detection_component: DetectionComponent = $"../DetectionComponent"



@export var attack_range:= 0.5
@export var attack_speed := 1

func _physics_process(delta: float) -> void:
	attack()

func target_in_range():
	return enemy.global_position.distance_squared_to(
		detection_component.player.global_position) < attack_range

func attack():
	if target_in_range():
		detection_component.player.health_component.damage(10.0)
