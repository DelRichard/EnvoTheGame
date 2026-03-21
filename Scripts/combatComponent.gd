class_name CombatComponent extends Node

@onready var health_component: HealthComponent = %HealthComponent
@onready var enemy: CharacterBody3D = $".."


@export var attack_damage:= 5.0
@export var attack_range:= 0.5
@export var attack_speed := 1

var can_attack := true
var attack_cooldown := 0.0

var player

func _ready():
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
	if can_attack:
		attack()

func target_in_range():
	var dist_sq = enemy.global_position.distance_squared_to(
		player.global_position)
	return dist_sq < attack_range * attack_range

func attack():
	if not target_in_range():
		return
	
	can_attack = false
	attack_cooldown = attack_speed
	
	player.health_component.damage(attack_damage, enemy.global_position)
	
