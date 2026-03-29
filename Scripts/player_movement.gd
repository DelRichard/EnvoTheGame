extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = %AnimatedSprite3D
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var camera_3d: Camera3D = %Camera3D
@onready var camera_pivot: Node3D = %CameraPivot
@onready var health_component: HealthComponent = %HealthComponent

@export var health_bar: ProgressBar 

var spawn_position: Vector3
var can_attack := true
var is_attacking: = false
var last_direction := "front"
var in_dialogue := false
var is_dead := false
var is_climbing := false
var rope_ref: Area3D = null

# MOVEMENT VARIABLES
@export var speed = 2.0 
@export var jump_velocity = 3.5
@export var climb_speed := 2.5

const SENSITIVITY = 0.003

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_jumping = false

# INPUT VARIABLES
var mouse_captured = true

# CAMERA VARIABLES 
var camera_rotation: Vector3 = Vector3.ZERO

# rotation limits
const MAX_LOOK_UP = deg_to_rad(40.0)  
const MAX_LOOK_DOWN = deg_to_rad(-40.0)  

@export var attack_damage := 100.0
@export var attack_range := 1.5
@export var attack_speed := 0.5
@export var knockback_force := 5.0
@export var attack_cooldown := 0.0

func enter_dialogue():
	in_dialogue = true
	velocity = Vector3.ZERO
	animated_sprite_3d.play("idle_" + last_direction)

func exit_dialogue():
	in_dialogue = false
	
func _ready():
	capture_mouse()
	await get_tree().process_frame
	QuestManager.start_quest("Crazy Introductions")
	health_bar.init_health(health_component.current_health)
	spawn_position = global_position

func enter_rope(rope):
	is_climbing = true
	rope_ref = rope
	velocity = Vector3.ZERO
	
func exit_rope():
	is_climbing = false
	rope_ref = null
	
# CAMERA
func capture_mouse():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true


func release_mouse():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false

func _unhandled_input(event):
		
	if event.is_action_pressed("ui_cancel"):
		if mouse_captured: release_mouse()
		else: capture_mouse()
		
	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * SENSITIVITY)
		handle_mouse_look(event.relative)


func handle_mouse_look(mouse_delta: Vector2) -> void:
	camera_rotation.x -= mouse_delta.y * SENSITIVITY
	camera_rotation.x = clamp(camera_rotation.x, MAX_LOOK_DOWN, MAX_LOOK_UP)
	camera_pivot.rotation.x = camera_rotation.x

func handle_climbing(_delta):
	var climb_input := 0.0
	
	if Input.is_action_pressed("w"):
		climb_input += 1
	if Input.is_action_pressed("s"):
		climb_input -= 1
	velocity = Vector3(0, climb_input * climb_speed, 0)
	if rope_ref:
		global_position.x = rope_ref.global_position.x
		global_position.z = rope_ref.global_position.z
	move_and_slide()
	if Input.is_action_just_pressed("ui_accept"):
		exit_rope()
		velocity.y = jump_velocity
		
# MOVEMENT
func _physics_process(delta):
	if is_climbing:
		handle_climbing(delta)
		return
	
	if in_dialogue:
		return 
		
	if not is_on_floor():
		velocity.y -= gravity * delta
		if is_jumping and animated_sprite_3d.frame == 2:
			animated_sprite_3d.pause()
	else:
		if is_jumping:
			is_jumping = false
			animated_sprite_3d.play("idle_back") 
			animated_sprite_3d.play()
			AudioManager.jump_sound()
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		is_jumping = true
		animated_sprite_3d.play("jump")
		animated_sprite_3d.frame = 0

	if Input.is_action_just_pressed("attack") and can_attack:
		is_attacking = true
		animated_sprite_3d.play("attack")
		AudioManager.whoosh_sound()
		attack()
	
	apply_cooldown(delta)
	
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
	if not is_jumping and not is_attacking:
		update_animations(input_dir)

#for combat
func apply_knockback(from_position: Vector3, force: float = 5.0):
	var dir = (global_position - from_position).normalized()
	velocity += dir * force

func apply_cooldown(delta: float):
	if not can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true

func attack():
	can_attack = false
	attack_cooldown = attack_speed
	
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= attack_range:
			enemy.health_component.damage(attack_damage,
			global_position,knockback_force)
	
	




# ANIMATION
func update_animations(input_dir):
	if input_dir == Vector2.ZERO:
		animated_sprite_3d.play("idle_" + last_direction)
	else:
		if input_dir.y < 0: 
			last_direction = "back"
			animated_sprite_3d.play("walk_back")
		elif input_dir.y > 0:
			last_direction = "front"
			animated_sprite_3d.play("walk_front")
		else: 
			last_direction = "side"
			animated_sprite_3d.play("walk_side")
			animated_sprite_3d.flip_h = input_dir.x < 0


func squash_effect():
	var tween = create_tween()
	tween.tween_property(animated_sprite_3d, "scale", Vector3(1.3, 0.6, 1.0), 0.08)
	tween.tween_property(animated_sprite_3d, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
	



func die():
	velocity = Vector3.ZERO
	set_process(false)
	set_physics_process(false)
	AudioManager.death_sound()
	animated_sprite_3d.play("death")
	await get_tree().create_timer(2.0).timeout
	restart_level()
	
func restart_level():
	AudioManager.revive_sound()
	respawn_player()
	
func respawn_player():
	velocity = Vector3.ZERO
	global_position = spawn_position
	is_dead = false
	is_attacking = false
	is_jumping = false
	health_component.reset_health()
	set_physics_process(true)
	set_process(true)
	animated_sprite_3d.play("idle_back")
	
func _on_died() -> void:
	if is_dead:
		return
	
	is_dead = true
	
	
	die()


func _on_player_hit(from_position: Vector3, knockback: float) -> void:
	AudioManager.hit_sound()
	animated_sprite_3d.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	animated_sprite_3d.modulate = Color.WHITE
	apply_knockback(from_position, knockback)


func _on_player_health_changed(current_health, max_health) -> void:
	health_bar.max_value = max_health
	health_bar.health = current_health


func _on_animation_finished() -> void:
	if animated_sprite_3d.animation == "attack":
		is_attacking = false


func _on_respawn_pressed() -> void:
	global_position = spawn_position
