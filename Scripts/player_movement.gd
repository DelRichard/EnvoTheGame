extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = %AnimatedSprite3D
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var camera_3d: Camera3D = %Camera3D
@onready var camera_pivot: Node3D = %CameraPivot

@onready var health_component: HealthComponent = %HealthComponent
@export var health_bar: ProgressBar 



var last_direction := "front"
var in_dialogue := false


var is_dead := false


# MOVEMENT VARIABLES
@export var speed = 2.0 
@export var jump_velocity = 3.5
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

func enter_dialogue():
	in_dialogue = true
	velocity = Vector3.ZERO
	animated_sprite_3d.play("idle_" + last_direction)

func exit_dialogue():
	in_dialogue = false
	
func _ready():
	capture_mouse()
	await get_tree().process_frame
	health_bar.init_health(health_component.current_health)
	
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
		# Rotate player horizontally (yaw)
		rotate_y(-event.relative.x * SENSITIVITY)

		# vertical rotation
		handle_mouse_look(event.relative)


func handle_mouse_look(mouse_delta: Vector2) -> void:
	camera_rotation.x -= mouse_delta.y * SENSITIVITY
	camera_rotation.x = clamp(camera_rotation.x, MAX_LOOK_DOWN, MAX_LOOK_UP)
	camera_pivot.rotation.x = camera_rotation.x


# MOVEMENT
func _physics_process(delta):
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
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		is_jumping = true
		animated_sprite_3d.play("jump")
		animated_sprite_3d.frame = 0

	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
	if not is_jumping:
		update_animations(input_dir)

#for combat
func apply_knockback(from_position: Vector3, force: float = 5.0):
	var dir = (global_position - from_position).normalized()
	velocity += dir * force


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
func die():
	# Stop movement
	velocity = Vector3.ZERO
	
	# Disable input
	set_process(false)
	set_physics_process(false)
	
	await get_tree().create_timer(2.0).timeout
	restart_level()


func restart_level():
	get_tree().reload_current_scene()


func _on_died() -> void:
	if is_dead:
		return
	
	is_dead = true
	
	print("You died")
	
	die()


func _on_player_hit(from_position: Vector3, knockback: float) -> void:
	print("Player got hit!")
	animated_sprite_3d.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	animated_sprite_3d.modulate = Color.WHITE
	apply_knockback(from_position, knockback)


func _on_player_health_changed(current_health, max_health) -> void:
	health_bar.max_value = max_health
	health_bar.health = current_health
