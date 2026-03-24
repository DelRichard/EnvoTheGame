class_name PlayerCombatComponent extends Node

@onready var health_component: HealthComponent = %HealthComponent
@onready var player: CharacterBody3D = $".."
@onready var animated_sprite_3d: AnimatedSprite3D = %AnimatedSprite3D




@export var attack_damage := 10.0
@export var attack_range := 1.5
@export var attack_speed := 0.5
@export var knockback_force := 5.0


var can_attack := true
var attack_cooldown := 0.0


func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true

	if Input.is_action_just_pressed("attack") and can_attack:
		attack()


func attack():
	can_attack = false
	attack_cooldown = attack_speed
	
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	for enemy in enemies:
		var dist = player.global_position.distance_to(enemy.global_position)
		if dist <= attack_range:
			enemy.health_component.damage(attack_damage,
			player.global_position,knockback_force)
	
	
	
