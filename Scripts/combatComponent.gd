class_name CombatComponent extends Node

@onready var health_component: HealthComponent = %HealthComponent
@onready var enemy: CharacterBody3D = $".."
@onready var detection_component: DetectionComponent = %DetectionComponent


@export var attack_damage:= 5.0
@export var attack_range:= 0.75
@export var attack_speed := 1
@export var attack_angle := 180.0 
@export var knockback_force := 5.0

var can_attack := true
var attack_cooldown := 0.0

var player

@export var lose_sight_time := 5.0

var time_since_seen_player := 0.0

func _ready():
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	update_behavior(delta)
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
	
	if not is_player_in_front():
		return
	
	can_attack = false
	attack_cooldown = attack_speed
	
	player.health_component.damage(attack_damage, enemy.global_position, knockback_force)
	
	
func update_behavior(delta: float) -> void:
	if detection_component.see_player:
		time_since_seen_player = 0.0
		
		if enemy.current_behavior != enemy.BehaviorState.ATTACK:
			enemy.be_attacking_player()
	else:
		time_since_seen_player += delta
		
		if time_since_seen_player >= lose_sight_time:
			if enemy.current_behavior == enemy.BehaviorState.ATTACK:
				enemy.be_wandering()


func is_player_in_front() -> bool:
	var to_player = (player.global_position - enemy.global_position).normalized()
	
	# Enemy forward direction (-Z in Godot)
	var forward = -enemy.global_transform.basis.z
	
	var dot = forward.dot(to_player)
	
	# Convert angle to dot threshold
	var threshold = cos(deg_to_rad(attack_angle * 0.5))
	
	return dot >= threshold
