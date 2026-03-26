extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var health_component: HealthComponent = %HealthComponent
@onready var audio_stream_player_3d: AudioStreamPlayer3D = %AudioStreamPlayer3D
@onready var fume: MeshInstance3D = $fume

@export var debug: bool = false
@export var attack_damage := 5.0
@export var attack_range := 1
@export var attack_cooldown := 5.0
@export var knockback_force := 5.0
@export var detect_range := 3.0

var can_attack := true
var attack_cooldown_timer := 0.0
var player
var current_state: States = States.HIDDEN

enum States {
	HIDDEN,
	HIDE,    # transition: hidden → idle
	IDLE,
	ATTACK,
	HIT,
	DEATH
}

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	fume.visible = false
	change_state(States.HIDDEN)



func change_state(new_state: States) -> void:
	current_state = new_state
	if debug:
		print("State → ", States.keys()[new_state])

	match current_state:
		States.HIDDEN:
			animated_sprite_3d.play("hidden")
			fume.visible = false

		States.HIDE:
			animated_sprite_3d.play("hide")     # plays once, then _on_animation_finished → IDLE

		States.IDLE:
			animated_sprite_3d.play("idle")
			fume.visible = false

		States.ATTACK:
			animated_sprite_3d.play("attack")
			fume.visible = true
			_perform_attack()

		States.HIT:
			animated_sprite_3d.play("hit")
			animated_sprite_3d.modulate = Color.RED

		States.DEATH:
			animated_sprite_3d.play("death")
			audio_stream_player_3d.play()

func _physics_process(delta: float) -> void:
	# Cooldown ticker (runs regardless of state)
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true

	match current_state:
		States.HIDDEN:
			if player_in_detect_range():
				change_state(States.HIDE)

		States.IDLE:
			if can_attack and target_in_range():
				change_state(States.ATTACK)


func _perform_attack() -> void:
	if not target_in_range():
		change_state(States.IDLE)
		return
	can_attack = false
	attack_cooldown_timer = attack_cooldown
	player.health_component.damage(attack_damage, global_position, knockback_force)

# ─── Helpers ──────────────────────────────────────────────────────────────────

func target_in_range() -> bool:
	return global_position.distance_squared_to(player.global_position) \
		< attack_range * attack_range

func player_in_detect_range() -> bool:
	return global_position.distance_squared_to(player.global_position) \
		< detect_range * detect_range



func _on_enemy_died() -> void:
	print("Enemy Killed!")
	fume.visible = false
	change_state(States.DEATH)
	await get_tree().create_timer(1.0).timeout
	queue_free()



func _on_enemy_hit(from_position: Vector3, knockback: float) -> void:
	print("Enemy Hit!")
	# Only interruptible states can be hit
	if current_state in [States.HIDDEN, States.HIDE, States.DEATH]:
		return
	change_state(States.HIT)


func _on_animation_finished() -> void:
	match animated_sprite_3d.animation:
		"hide":
			change_state(States.IDLE)
		"attack":
			change_state(States.IDLE)
		"hit":
			animated_sprite_3d.modulate = Color.WHITE
			change_state(States.IDLE)
