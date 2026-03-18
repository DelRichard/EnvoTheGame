extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D


# MOVEMENT VARIABLES
@export var speed = 2.0 # changed to export so it can be adjusted on editor
@export var jump_velocity = 2.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_jumping = false
var wants_jump := false

var direction : Vector3 = Vector3.ZERO

var rotation_speed: float = 6.0
var is_moving: bool = false

# Smart path update logic
var current_target: Vector3 = Vector3.ZERO
var target_update_threshold: float = 1.0  
var last_path_update_time: float = 0.0
var min_path_update_interval: float = 0.1  # Minimum time between updates


# BEHAVIOUR VARIABLES
enum BehaviorState {IDLE, WANDER, MOVE_TO_TARGET, FOLLOW}
var current_behavior: BehaviorState = BehaviorState.WANDER

enum WanderState {IDLE, WAITING_TO_MOVE, MOVE}
var wander_state: WanderState = WanderState.IDLE

@export var idle_wait_time: float = 2.0
@export var follow_distance: float = 1.0

@export var my_target: Node3D
@export var following_target: Node3D
@export var debug := false

var idle_timer_count: float = 0.0
var was_idle: bool = false


# MOVEMENT
func _physics_process(delta):
	# behaviour
	match current_behavior:
		BehaviorState.IDLE:
			idle()
		BehaviorState.WANDER:
			wander(delta)
		BehaviorState.MOVE_TO_TARGET:
			go_to_target(my_target)
		BehaviorState.FOLLOW:
			follow(following_target)
	
	# navigation
	last_path_update_time += delta
	
	if is_moving:
		update_movement()
	
	# movement
	if not is_on_floor():
		velocity.y -= gravity * delta
		if is_jumping and animated_sprite_3d.frame == 1:
			animated_sprite_3d.pause()
	else:
		if is_jumping:
			is_jumping = false
			animated_sprite_3d.play("idle_back") 
			animated_sprite_3d.play()
	if wants_jump and is_on_floor():
		velocity.y = jump_velocity
		is_jumping = true
		animated_sprite_3d.play("jump")
		animated_sprite_3d.frame = 0


	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	update_animations(Vector2(direction.x, direction.z))
	
	move_and_slide()



# ANIMATION
func update_animations(direction):
	if direction == Vector2.ZERO:
		if animated_sprite_3d.animation.contains("walk"):
			var suffix = animated_sprite_3d.animation.split("_")[1]
			animated_sprite_3d.play("idle_" + suffix)
	else:
		if direction.y < 0: 
			animated_sprite_3d.play("walk_back")
		elif direction.y > 0:
			animated_sprite_3d.play("walk_front")
		else: 
			animated_sprite_3d.play("walk_side")
			animated_sprite_3d.flip_h = direction.x < 0




func update_movement() -> void:
	if not navigation_agent_3d.is_navigation_finished():
		var current_position = global_transform.origin
		var next_position = navigation_agent_3d.get_next_path_position()
		direction = (next_position - current_position).normalized()
		
		
		var new_velocity = direction * speed
		
		navigation_agent_3d.velocity = new_velocity
	else:
		stop_movement()



func stop_movement() -> void:
	direction = Vector3.ZERO
	is_moving = false
	navigation_agent_3d.target_position = global_transform.origin
	navigation_agent_3d.velocity = Vector3.ZERO
	current_target = Vector3.ZERO
	last_path_update_time = 0.0


func move_to_target(target: Vector3) -> void:
	var nav_map = navigation_agent_3d.get_navigation_map()
	
	# Guard: navigation map hasn't finished first sync yet
	if NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		return
	
	var safe_target = NavigationServer3D.map_get_closest_point(nav_map, target)
	
	var target_distance = current_target.distance_to(safe_target)
	var should_update = target_distance > target_update_threshold and last_path_update_time >= min_path_update_interval
	
	if not is_moving:
		should_update = true
	
	if should_update:
		navigation_agent_3d.target_position = safe_target
		current_target = safe_target
		is_moving = true
		last_path_update_time = 0.0



# Signals
func _on_navigation_agent_3d_target_reached() -> void:
	stop_movement()


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if is_on_floor():
		velocity = velocity.move_toward(safe_velocity, 0.25)
		
		var horizontal_velocity = Vector3(safe_velocity.x, 0, safe_velocity.z)
		if horizontal_velocity.length() > 0.01:
			direction = horizontal_velocity.normalized()
		else:
			stop_movement()








# Idling
func idle() -> void:
	if not was_idle:
		stop_movement()
		wander_state = WanderState.IDLE
		was_idle = true


func go_to_target(currentTarget: Node3D) -> void:
	was_idle = false
	move_to_target(currentTarget.global_position)


func follow(myFollowTarget: Node3D) -> void:
	was_idle = false
	
	var direction = myFollowTarget.global_position - global_position
	var distance = direction.length()
	
	if distance > follow_distance:
		move_to_target(myFollowTarget.global_position)
	else:
		stop_movement()


# Wandering
func wander(delta: float) -> void:
	was_idle = false
	
	match wander_state:
		WanderState.IDLE:
			wander_idle()
		WanderState.WAITING_TO_MOVE:
			wander_waiting_to_move(delta)
		WanderState.MOVE:
			if not is_moving:
				wander_state = WanderState.IDLE

func wander_idle() -> void:
	stop_movement()
	idle_timer_count = idle_wait_time
	wander_state = WanderState.WAITING_TO_MOVE

func wander_waiting_to_move(delta: float) -> void:
	idle_timer_count -= delta
	
	if idle_timer_count <= 0.0:
		var target = get_new_target_location()
		move_to_target(target)
		wander_state = WanderState.MOVE


# Helper
func get_new_target_location() -> Vector3:
	var offset_x = randf_range(0.5, 3.0) * (-1 if randf() < 0.5 else 1)
	var offset_z = randf_range(0.5, 3.0) * (-1 if randf() < 0.5 else 1)
	return global_transform.origin + Vector3(offset_x, 0, offset_z)


# Testing
func be_idle():
	current_behavior = BehaviorState.IDLE

func be_wandering():
	current_behavior = BehaviorState.WANDER
	wander_state = WanderState.IDLE

func go_there():
	current_behavior = BehaviorState.MOVE_TO_TARGET

func be_following():
	current_behavior = BehaviorState.FOLLOW



func on_navigation_target_reached() -> void:
	if debug:
		print("target reached")
	if current_behavior == BehaviorState.WANDER:
		wander_state = WanderState.IDLE
	if current_behavior == BehaviorState.MOVE_TO_TARGET:
		current_behavior = BehaviorState.IDLE
