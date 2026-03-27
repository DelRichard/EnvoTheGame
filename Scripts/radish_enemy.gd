extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var audio_stream_player_3d: AudioStreamPlayer3D = %AudioStreamPlayer3D
@onready var head: Node3D = $Head
@onready var ray_cast_3d: RayCast3D = $Head/RayCast3D


enum BehaviorState { IDLE, WANDER, MOVE_TO_TARGET, FOLLOW, HIT, DEATH, ATTACK}
enum WanderState   { IDLE, WAITING_TO_MOVE, MOVE }

@export var speed: float = 1.5
@export var jump_velocity: float = 2.0
@export var idle_wait_time: float = 2.0
@export var follow_distance: float = 0.5

@export var current_behavior: BehaviorState = BehaviorState.WANDER
@export var my_target: Node3D
@export var following_target: Node3D
@export var debug: bool = false

# MOVEMENT VARIABLES
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_jumping: bool = false
var wants_jump: bool = false
var direction: Vector3 = Vector3.ZERO
var rotation_speed: float = 6.0
var is_moving: bool = false

# NAVIGATION VARIABLES
var current_target: Vector3 = Vector3.ZERO
var target_update_threshold: float = 0.5
var last_path_update_time: float = 0.0
var min_path_update_interval: float = 0.1

# BEHAVIOUR VARIABLES
var wander_state: WanderState = WanderState.IDLE
var idle_timer_count: float = 0.0
var was_idle: bool = false

var is_dying: bool = false
var player

var is_attacking := false




@export var horizontal_fov := 180.0
@export var vertical_fov := 120.0  
@export var max_view_distance := 5.0


var player_head

var see_player := false
var last_state := false


@export var attack_damage:= 5.0
@export var attack_range:= 0.5
@export var attack_cooldown := 1.0
@export var attack_angle := 180.0 
@export var knockback_force := 5.0

var can_attack := true
var attack_cooldown_timer := 0.0


@export var lose_sight_time := 5.0

var time_since_seen_player := 0.0





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
			follow(following_target, delta)
		BehaviorState.ATTACK:
			follow(player, delta)
		BehaviorState.HIT:
			animated_sprite_3d.play("hit")
			animated_sprite_3d.modulate = Color.RED
			await get_tree().create_timer(0.1).timeout
			animated_sprite_3d.modulate = Color.WHITE
			
		BehaviorState.DEATH:
			if not is_dying:
				is_dying = true
				animated_sprite_3d.play("death")
				audio_stream_player_3d.play()
				await animated_sprite_3d.animation_finished
				queue_free()
			return

	# Navigation
	last_path_update_time += delta

	if is_moving:
		update_movement()
		
	rotate_to_movement_direction(delta)

	# Gravity & jumping
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

	# Horizontal movement
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	update_animations(Vector2(direction.x, direction.z))
	
	
	#attack
	update_behavior(delta)
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true
	
	if can_attack:
		attack()
	
	if player and can_see_player() and is_in_fov() and has_line_of_sight():
		see_player = true
	else:
		see_player = false
	
	if see_player != last_state:
		if debug:
			print("See player:", see_player)
		last_state = see_player
	
	
	move_and_slide()


# MOVEMENT

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

#for combat
func apply_knockback(from_position: Vector3, force: float = 5.0):
	var dir = (global_position - from_position).normalized()
	velocity += dir * force


# ANIMATION

func get_view_direction() -> String:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return "back"

	var to_camera = camera.global_position - global_position
	to_camera.y = 0
	if to_camera.length() < 0.1:
		return "back"
	to_camera = to_camera.normalized()

	# NPC faces -Z in Godot's local space
	var npc_forward = -global_transform.basis.z
	npc_forward.y = 0
	npc_forward = npc_forward.normalized()

	# dot > 0  → camera is in front of NPC (you see their face)
	# dot < 0  → camera is behind NPC (you see their back)
	var dot   = npc_forward.dot(to_camera)
	var cross = npc_forward.cross(to_camera).y  # positive = camera to NPC's right

	if abs(dot) >= abs(cross):
		return "front" if dot >= 0 else "back"
	else:
		return "side"





func update_animations(movement_dir: Vector2) -> void:
	if is_jumping or is_attacking:
		return
	
	if current_behavior == BehaviorState.DEATH:
		return

	var view_dir = get_view_direction()
	var prefix   = "walk_" if movement_dir != Vector2.ZERO else "idle_"

	animated_sprite_3d.play(prefix + view_dir)

	if view_dir == "side":
		animated_sprite_3d.play("walk_side")

func rotate_to_movement_direction(delta: float) -> void:
	if direction.length() > 0.01:
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)


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
func follow(myFollowTarget: Node3D, delta: float) -> void:
	was_idle = false

	var direction = myFollowTarget.global_position - global_position
	var distance = direction.length()

	if distance > follow_distance:
		move_to_target(myFollowTarget.global_position)
	else:
		if direction.length() > 0.01:
			var target_rot = atan2(-direction.x, -direction.z)
			rotation.y = lerp_angle(rotation.y, target_rot, rotation_speed * delta)
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





func target_in_range():
	var dist_sq = global_position.distance_squared_to(
		player.global_position)
	return dist_sq < attack_range * attack_range

func attack():
	if not target_in_range():
		return
	if not is_player_in_front():
		return
	
	can_attack = false
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	animated_sprite_3d.play("attack")
	player.health_component.damage(attack_damage, global_position, knockback_force)
	await animated_sprite_3d.animation_finished
	is_attacking = false

	
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


func can_see_player() -> bool:
	if not player:
		return false
		
	var distance = head.global_position.distance_to(player_head.global_position)
	return distance <= max_view_distance


func is_in_fov() -> bool:
	var to_player = player_head.global_position - head.global_position
	var local_dir = head.global_transform.basis.inverse() * to_player
	
	var horizontal_angle = rad_to_deg(atan2(local_dir.x, -local_dir.z))
	var vertical_angle = rad_to_deg(atan2(local_dir.y, -local_dir.z))
	
	return (
		abs(horizontal_angle) <= horizontal_fov * 0.5
		and
		abs(vertical_angle) <= vertical_fov * 0.5
	)


func has_line_of_sight() -> bool:
	ray_cast_3d.target_position = ray_cast_3d.to_local(player_head.global_position)
	ray_cast_3d.force_raycast_update()
	# If nothing is in the way, we can see them
	if not ray_cast_3d.is_colliding():
		return true
	# If something is in the way, check if it's the player themselves
	return ray_cast_3d.get_collider() == player




func is_player_in_front() -> bool:
	var to_player = (player.global_position - global_position).normalized()
	
	# Enemy forward direction (-Z in Godot)
	var forward = -global_transform.basis.z
	
	var dot = forward.dot(to_player)
	
	# Convert angle to dot threshold
	var threshold = cos(deg_to_rad(attack_angle * 0.5))
	
	return dot >= threshold







# SIGNALS

func _on_navigation_agent_3d_target_reached() -> void:
	#if debug:
		#print("Target reached")
	if current_behavior == BehaviorState.WANDER:
		wander_state = WanderState.IDLE
	if current_behavior == BehaviorState.MOVE_TO_TARGET:
		current_behavior = BehaviorState.IDLE
	


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if is_on_floor():
		velocity = velocity.move_toward(safe_velocity, 0.25)

		var horizontal_velocity = Vector3(safe_velocity.x, 0, safe_velocity.z)
		if horizontal_velocity.length() > 0.01:
			direction = horizontal_velocity.normalized()
		else:
			stop_movement()



func _on_enemy_died() -> void:
	print("Enemy Killed!")
	current_behavior = BehaviorState.DEATH


func _on_enemy_hit(from_position: Vector3, knockback: float) -> void:
	print("Enemy Hit!")
	current_behavior = BehaviorState.HIT
	apply_knockback(from_position, knockback)
	if current_behavior != BehaviorState.ATTACK:
		var dir = (from_position - global_position)
		if dir.length() > 0.01:
			var target_rot = atan2(-dir.x, -dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 1.0)
