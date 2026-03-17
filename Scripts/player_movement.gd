extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = %AnimatedSprite3D
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var camera_3d: Camera3D = %Camera3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.003

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_jumping = false
var mouse_captured = true

func _ready():
	capture_mouse()

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
		camera_3d.rotate_x(-event.relative.y * SENSITIVITY)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		if is_jumping and animated_sprite_3d.frame == 1:
			animated_sprite_3d.pause()
	else:
		if is_jumping:
			is_jumping = false
			animated_sprite_3d.play("idle_back") 
			animated_sprite_3d.play()
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		animated_sprite_3d.play("jump")
		animated_sprite_3d.frame = 0

	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	if not is_jumping:
		update_animations(input_dir)

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
