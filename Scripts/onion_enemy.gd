extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var health_component: HealthComponent = %HealthComponent
@onready var audio_stream_player_3d: AudioStreamPlayer3D = %AudioStreamPlayer3D
@onready var fume: MeshInstance3D = $fume

@export var debug: bool = false

@export var attack_damage:= 5.0
@export var attack_range:= 1
@export var attack_speed := 1
@export var knockback_force := 5.0
@export var detect_range := 3.0

var can_attack := true
var attack_cooldown := 0.0

var is_attacking:= false
var is_dead:= false


var player






func _ready():
	player = get_tree().get_first_node_in_group("Player")
	animated_sprite_3d.play("hidden")
	fume.visible = false


func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true

	if can_attack and target_in_range() and not is_attacking:
		is_attacking = true
		animated_sprite_3d.play("attack")
		attack()
	
	elif not is_attacking:
		fume.visible = false
		if animated_sprite_3d.animation != "idle":
			animated_sprite_3d.play("idle")


func target_in_range():
	var dist_sq = global_position.distance_squared_to(
		player.global_position)
	return dist_sq < attack_range * attack_range


func player_in_detect_range():
	var dist_sq = global_position.distance_squared_to(player.global_position)
	return dist_sq < detect_range * detect_range


func attack():
	if not target_in_range():
		return
	
	fume.visible = true
	can_attack = false
	attack_cooldown = attack_speed
	
	player.health_component.damage(attack_damage, global_position, knockback_force)




func _on_enemy_died() -> void:
	print("Enemy Killed!")
	animated_sprite_3d.play("death")
	audio_stream_player_3d.play()
	await get_tree().create_timer(1.0).timeout
	queue_free()



func _on_enemy_hit(from_position: Vector3, knockback: float) -> void:
	print("Enemy Hit!")
	animated_sprite_3d.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	animated_sprite_3d.modulate = Color.WHITE


func _on_animation_finished() -> void:
	if animated_sprite_3d.animation == "attack":
		is_attacking = false
