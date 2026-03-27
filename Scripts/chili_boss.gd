extends CharacterBody3D

signal boss_killed(boss_id)

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var audio_stream_player_3d: AudioStreamPlayer3D = %AudioStreamPlayer3D
@onready var head: Node3D = $Head
@onready var ray_cast_3d: RayCast3D = $Head/RayCast3D

enum BehaviorState { IDLE, WANDER, MOVE_TO_TARGET, FOLLOW, ATTACK, HIT, DEATH, DASHING }
enum WanderState   { IDLE, WAITING_TO_MOVE, MOVE }

@export_group("Movement Settings")
@export var speed: float = 0.5
@export var rotation_speed: float = 6.0
@export var follow_distance: float = 0.75

@export_group("Behavior Settings")
@export var current_behavior: BehaviorState = BehaviorState.IDLE
@export var idle_wait_time: float = 2.0
@export var lose_sight_time: float = 5.0
@export var debug: bool = false

@export_group("Combat Settings")
@export var attack_damage: float = 5.0
@export var attack_range: float = 0.75
@export var attack_cooldown: float = 1.0 
@export var knockback_force: float = 30.0

@export var dash_speed: float = 5.0
@export var dash_duration: float = 0.6
@export var dash_cooldown: float = 3.0
@export var dash_trigger_range: float = 5.0 # Distance where it starts the dash

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

@export_group("Targets")
@export var my_target: Node3D
@export var following_target: Node3D
@export var max_view_distance := 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction: Vector3 = Vector3.ZERO
var is_moving: bool = false

var current_target: Vector3 = Vector3.ZERO
var target_update_threshold: float = 1.0
var last_path_update_time: float = 0.0
var min_path_update_interval: float = 0.1

var wander_state: WanderState = WanderState.IDLE
var idle_timer_count: float = 0.0
var was_idle: bool = false

var player: CharacterBody3D
var player_head: Node3D
var see_player := false
var last_state := false
var time_since_seen_player := 0.0

var can_attack := true
var attack_cooldown_timer := 0.0
var is_dying := false

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
			if not current_behavior == BehaviorState.DASHING:
				follow(player, delta)
			process_attack_logic(delta)
		BehaviorState.HIT:
			animated_sprite_3d.play("hit")
			squash_effect()
			await get_tree().create_timer(0.1).timeout # hit stun
			if see_player:
				current_behavior = BehaviorState.ATTACK
			else:
				current_behavior = BehaviorState.IDLE
		BehaviorState.DASHING:
			process_dash(delta)
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

	
	#detection
	
	if player and can_see_player() and has_line_of_sight():
		see_player = true
	else:
		see_player = false
	
	if see_player != last_state:
		if debug:
			print("See player:", see_player)
		last_state = see_player
		
	#combat
	
	update_behavior(delta)
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true


	# Gravity & jumping
	if not is_on_floor():
		velocity.y -= gravity * delta


	handle_movement(delta)
	
	move_and_slide()
	
	update_animations(Vector2(direction.x, direction.z))




# MOVEMENT
func handle_movement(_delta: float) -> void:
	if current_behavior == BehaviorState.DASHING:
		return
	if is_moving:
		update_movement()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

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
	velocity += dir * (force/2)

func process_attack_logic(delta: float) -> void:
	if not player: return
	
	var dist = global_position.distance_to(player.global_position)
	
	# If we are close enough to start a dash and cooled down
	if dist <= dash_trigger_range and can_attack:
		start_dash_sequence()
	else:
		# Otherwise, just keep walking toward them normally
		follow(player, delta)

func start_dash_sequence() -> void:
	print("DASH STARTING")
	can_attack = false
	attack_cooldown_timer = dash_cooldown
	
	# 1. Telegraph: Briefly stop and face the player
	stop_movement()
	animated_sprite_3d.play("idle")
	
	# Wait for a split second so the player can react
	await get_tree().create_timer(0.5).timeout
	
	# 2. Set Dash Direction
	dash_direction = (player.global_position - global_position).normalized()
	dash_direction.y = 0 # Keep it on the ground
	
	current_behavior = BehaviorState.DASHING
	dash_timer = dash_duration
	is_dashing = true
	
	animated_sprite_3d.play("idle") 

func process_dash(delta: float) -> void:
	if dash_timer > 0:
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
		dash_timer -= delta
		
		# Check for "Chomp" during the dash
		check_for_chomp_collision()
	else:
		# Dash finished
		is_dashing = false
		current_behavior = BehaviorState.ATTACK
		velocity.x = 0
		velocity.z = 0

func check_for_chomp_collision() -> void:
	# If the player is within tiny range during the dash, hit them
	if global_position.distance_to(player.global_position) < 1.5:
		animated_sprite_3d.play("attack") 
		player.squash_effect()
		player.health_component.damage(attack_damage, global_position, knockback_force)
		# Optional: Stop dashing once we hit
		dash_timer = 0
		print("CHOMP")



# ANIMATION

func update_animations(movement_dir: Vector2) -> void:
	# 1. If we are dying, don't do anything else
	if current_behavior == BehaviorState.DEATH:
		return

	# 2. If the attack animation is playing, let it finish
	if animated_sprite_3d.animation == "attack" and animated_sprite_3d.is_playing():
		return

	# 3. Otherwise, do normal movement animations
	var animation = "walk" if movement_dir != Vector2.ZERO else "idle"
	animated_sprite_3d.play(animation)

func squash_effect():
	var tween = create_tween()
	tween.tween_property(animated_sprite_3d, "scale", Vector3(1.1, 0.9, 1.0), 0.1)
	tween.tween_property(animated_sprite_3d, "scale", Vector3(1.0, 1.0, 1.0), 0.1)


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


func target_in_range():
	var dist_sq = global_position.distance_squared_to(
		player.global_position)
	return dist_sq < attack_range * attack_range

func attack():
	if not target_in_range():
		return
	
	can_attack = false
	attack_cooldown_timer = attack_cooldown
	
	player.health_component.damage(attack_damage, global_position, knockback_force)
	
	
func update_behavior(delta: float) -> void:
	if see_player:
		time_since_seen_player = 0.0
		
		var locked_states = [BehaviorState.ATTACK, BehaviorState.DASHING, BehaviorState.HIT, BehaviorState.DEATH]
		if current_behavior not in locked_states:
			be_attacking_player()
	else:
		time_since_seen_player += delta
		
		if time_since_seen_player >= lose_sight_time:
			if current_behavior == BehaviorState.ATTACK:
				be_wandering()




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




# SIGNALS

func _on_navigation_agent_3d_target_reached() -> void:
	#if debug:
		#print("Target reached")
	if current_behavior == BehaviorState.WANDER:
		wander_state = WanderState.IDLE
	if current_behavior == BehaviorState.MOVE_TO_TARGET:
		current_behavior = BehaviorState.IDLE
	


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if current_behavior == BehaviorState.DASHING:
		return
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
	emit_signal("boss_killed", "boss")


func _on_enemy_hit(from_position: Vector3, knockback: float) -> void:
	print("Enemy Hit!")
	current_behavior = BehaviorState.HIT
	apply_knockback(from_position, knockback)
	if current_behavior != BehaviorState.FOLLOW:
		var dir = (from_position - global_position)
		if dir.length() > 0.01:
			var target_rot = atan2(-dir.x, -dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot, 1.0)
