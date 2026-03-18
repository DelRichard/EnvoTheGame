extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = %AnimatedSprite3D
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var camera_3d: Camera3D = %Camera3D
@onready var camera_pivot: Node3D = %CameraPivot

# MOVEMENT VARIABLES
@export var speed = 2.0 # changed to export so it can be adjusted on editor
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


func _ready():
	capture_mouse()

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


# ANIMATION
func update_animations(input_dir):
	if input_dir == Vector2.ZERO:
		if animated_sprite_3d.animation.contains("walk"):
			var suffix = animated_sprite_3d.animation.split("_")[1]
			animated_sprite_3d.play("idle_" + suffix)
	else:
		if input_dir.y < 0: 
			animated_sprite_3d.play("walk_back")
		elif input_dir.y > 0:
			animated_sprite_3d.play("walk_front")
		else: 
			animated_sprite_3d.play("walk_side")
			animated_sprite_3d.flip_h = input_dir.x < 0
