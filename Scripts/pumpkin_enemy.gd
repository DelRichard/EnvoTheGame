extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var audio_stream_player_3d: AudioStreamPlayer3D = %AudioStreamPlayer3D
@onready var head: Node3D = $Head
@onready var ray_cast_3d: RayCast3D = $Head/RayCast3D


@export var max_view_distance := 10.0

enum BehaviorState { IDLE, WANDER, MOVE_TO_TARGET, FOLLOW, ATTACK }
enum WanderState   { IDLE, WAITING_TO_MOVE, MOVE }

@export var speed: float = 1.5
@export var jump_velocity: float = 2.0
@export var jump_move_speed: float = 2.0    
@export var jump_interval: float = 1.0   
@export var idle_wait_time: float = 2.0
@export var follow_distance: float = 0.75

@export var current_behavior: BehaviorState = BehaviorState.WANDER
@export var my_target: Node3D
@export var following_target: Node3D
@export var debug: bool = false

# MOVEMENT VARIABLES
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_jumping: bool = false
var direction: Vector3 = Vector3.ZERO
var is_moving: bool = false

# NAVIGATION VARIABLES
var current_target: Vector3 = Vector3.ZERO
var target_update_threshold: float = 1.0
var last_path_update_time: float = 0.0
var min_path_update_interval: float = 0.1

# BEHAVIOUR VARIABLES
var wander_state: WanderState = WanderState.IDLE
var idle_timer_count: float = 0.0
var was_idle: bool = false

# JUMP MOVEMENT
var jump_timer: float = 0.0

# COMBAT
@export var attack_damage := 10.0
@export var attack_range := 1.0
@export var knockback_force := 15.0
@export var attack_cooldown: float = 1.5

# JUMP ATTACK
@export var jump_attack_velocity: float = 5.0   
@export var jump_attack_speed: float = 4.0    
@export var jump_attack_land_range: float = 1.0 

var can_attack := true
var attack_cooldown_timer: float = 0.0
var is_jump_attacking: bool = false
var jump_attack_has_left_floor: bool = false 

var player
@export var lose_sight_time := 5.0
var time_since_seen_player := 0.0


var player_head

var see_player := false
var last_state := false

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	player_head = player.get_node("CameraPivot")


func _physics_process(delta: float) -> void:
	# Behaviour
	match current_behavior:
		BehaviorState.IDLE:
			idle()
		BehaviorState.WANDER:
			wander(delta)
		BehaviorState.MOVE_TO_TARGET:
			go_to_target(my_target)
		BehaviorState.FOLLOW:
			follow(following_target)
		BehaviorState.ATTACK:
			if not is_jump_attacking: #only follow if not mid-jump
				follow(player)
	
	# combat
	update_behavior(delta)
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0.0:
			can_attack = true
	
	if can_attack and not is_jump_attacking:  
		attack()

	# Navigation
	last_path_update_time += delta
	if is_moving:
		update_movement()


	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		# check if left ground to start detecting landing area
		if is_jump_attacking:
			jump_attack_has_left_floor = true
		if is_jumping and animated_sprite_3d.frame == 1:
			animated_sprite_3d.pause()
	else:
		# Normal jump landing
		if is_jumping and not is_jump_attacking:
			is_jumping = false
			animated_sprite_3d.play("idle")
			animated_sprite_3d.play()

		# Jump attack landing
		if is_jump_attacking and jump_attack_has_left_floor:
			_on_jump_attack_land()

	# Regular jumping, disabled during a jump attack
	jump_timer += delta
	if is_moving and is_on_floor() and not is_jumping and not is_jump_attacking and jump_timer >= jump_interval:
		jump_timer = 0.0
		velocity.y = jump_velocity
		velocity.x = direction.x * jump_move_speed
		velocity.z = direction.z * jump_move_speed
		is_jumping = true
		animated_sprite_3d.play("jump")
		animated_sprite_3d.frame = 0


	# smooth landing
	if is_on_floor() and not is_jumping:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	handle_detection(delta)
	
	move_and_slide()


# MOVEMENT

func update_movement() -> void:
	if not navigation_agent_3d.is_navigation_finished():
		var current_position = global_transform.origin
		var next_position = navigation_agent_3d.get_next_path_position()
		direction = (next_position - current_position).normalized()
	else:
		stop_movement()


func stop_movement() -> void:
	direction = Vector3.ZERO
	is_moving = false
	navigation_agent_3d.target_position = global_transform.origin
	navigation_agent_3d.velocity = Vector3.ZERO
	current_target = Vector3.ZERO
	last_path_update_time = 0.0
	jump_timer = 0.0


func move_to_target(target: Vector3) -> void:
	var nav_map = navigation_agent_3d.get_navigation_map()
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


# BEHAVIOUR

# idle
func idle() -> void:
	if not was_idle:
		stop_movement()
		wander_state = WanderState.IDLE
		was_idle = true


# wander
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


func get_new_target_location() -> Vector3:
	var offset_x = randf_range(0.5, 3.0) * (-1 if randf() < 0.5 else 1)
	var offset_z = randf_range(0.5, 3.0) * (-1 if randf() < 0.5 else 1)
	return global_transform.origin + Vector3(offset_x, 0, offset_z)


# move to target
func go_to_target(currentTarget: Node3D) -> void:
	was_idle = false
	move_to_target(currentTarget.global_position)


# follow
func follow(myFollowTarget: Node3D) -> void:
	was_idle = false

	var direction = myFollowTarget.global_position - global_position
	var distance = direction.length()

	if distance > follow_distance:
		move_to_target(myFollowTarget.global_position)
	else:
		stop_movement()


# Call these externally to change behaviour

func be_idle() -> void:
	current_behavior = BehaviorState.IDLE


func be_wandering() -> void:
	current_behavior = BehaviorState.WANDER
	wander_state = WanderState.IDLE


func go_there() -> void:
	current_behavior = BehaviorState.MOVE_TO_TARGET


func be_following() -> void:
	current_behavior = BehaviorState.FOLLOW

func be_attacking_player() -> void:
	current_behavior = BehaviorState.ATTACK


# COMBAT
func apply_knockback(from_position: Vector3, force: float = 5.0):
	var dir = (global_position - from_position).normalized()
	velocity += dir * force


func target_in_range():
	var dist_sq = global_position.distance_squared_to(
		player.global_position)
	return dist_sq < attack_range * attack_range


func attack() -> void:
	if not target_in_range():
		return

	can_attack = false
	attack_cooldown_timer = attack_cooldown

	# stop movement and leap toward the player
	stop_movement()
	is_jump_attacking = true
	jump_attack_has_left_floor = false
	is_jumping = true

	# snapshot the player's position
	var target_pos = player.global_position

	var leap_dir = (target_pos - global_position).normalized()
	var horizontal_dist = Vector2(
		target_pos.x - global_position.x,
		target_pos.z - global_position.z
	).length()

	# Physics: time to leave and return to the same Y = (2 * vy) / g
	# Divide horizontal distance by that time to get the exact landing speed.
	var time_of_flight = (2.0 * jump_attack_velocity) / gravity
	var horizontal_speed = horizontal_dist / time_of_flight

	velocity.y = jump_attack_velocity
	velocity.x = leap_dir.x * horizontal_speed
	velocity.z = leap_dir.z * horizontal_speed

	animated_sprite_3d.play("jump")
	animated_sprite_3d.frame = 0


func _on_jump_attack_land() -> void:
	is_jump_attacking = false
	jump_attack_has_left_floor = false
	is_jumping = false

	animated_sprite_3d.play("smash")

	# hit the player if they're within landing range 
	var land_dist_sq = global_position.distance_squared_to(player.global_position)
	if land_dist_sq < jump_attack_land_range * jump_attack_land_range:
		player.health_component.damage(attack_damage, global_position, knockback_force)
		player.squash_effect()


func update_behavior(delta: float) -> void:
	if see_player:
		time_since_seen_player = 0.0
		
		if current_behavior != BehaviorState.ATTACK:
			be_attacking_player()
	else:
		time_since_seen_player += delta
		
		if time_since_seen_player >= lose_sight_time:
			if current_behavior == BehaviorState.ATTACK:
				be_wandering()



func handle_detection(_delta: float) -> void:
	if player and can_see_player() and has_line_of_sight():
		see_player = true
	else:
		see_player = false
	
	if see_player != last_state:
		if debug:
			print("See player:", see_player)
		last_state = see_player


func can_see_player() -> bool:
	if not player:
		return false
		
	var distance = head.global_position.distance_to(player_head.global_position)
	return distance <= max_view_distance


func has_line_of_sight() -> bool:
	ray_cast_3d.target_position = ray_cast_3d.to_local(player_head.global_position)
	ray_cast_3d.force_raycast_update()
	# If nothing is in the way, we can see them
	if not ray_cast_3d.is_colliding():
		return true
	# If something is in the way, check if it's the player themselves
	return ray_cast_3d.get_collider() == player



# SIGNALS

func _on_navigation_agent_3d_target_reached() -> void:
	#if debug:
		#print("Target reached")
	if current_behavior == BehaviorState.WANDER:
		wander_state = WanderState.IDLE
	if current_behavior == BehaviorState.MOVE_TO_TARGET:
		current_behavior = BehaviorState.IDLE


func _on_enemy_died() -> void:
	print("Enemy Killed!")
	audio_stream_player_3d.play()
	await get_tree().create_timer(1.0).timeout
	queue_free()


func _on_enemy_hit(from_position: Vector3, knockback: float) -> void:
	print("Enemy Hit!")
	animated_sprite_3d.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	animated_sprite_3d.modulate = Color.WHITE
	apply_knockback(from_position, knockback)
	
