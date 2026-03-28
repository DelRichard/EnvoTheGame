extends CharacterBody3D
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D
@onready var interact_area: Area3D = $Interact_Area
@onready var interact_icon = get_node("/root/Main/Player/Interact_Icon")
@export var npc_id: String = "Gold_Foot"
@export var initial_dialogue: DialogueData

@export var move_speed: float = 2.0

@export var point_a: Node3D
@export var point_b: Node3D

@onready var boss_area_block: CollisionShape3D = $"../World/AreaBoundaries/bossAreaBlock"
@onready var pumpkin_area_block: CollisionShape3D = $"../World/AreaBoundaries/pumpkinAreaBlock"
@onready var village_block: CollisionShape3D = $"../World/AreaBoundaries/villageBlock"
@onready var toxic_gas_block: CollisionShape3D = $"../World/AreaBoundaries/toxicGasBlock"

@onready var big_fog: FogVolume = $"../WorldEnvironment/BigFog"
@onready var pond: MeshInstance3D = $"../World/NavigationRegion3D/pond"
var clean_water = preload("res://assets/materials/water.tres")
@onready var machine: AnimationPlayer = $"../World/NavigationRegion3D/machine/gear_001/AnimationPlayer"

@onready var ogre: CharacterBody3D = $"../Ogre"

var is_moving := false
var player_in_range := false
var has_talked := false
var in_dialogue := false
var dialogue_target: Node3D = null
var found_two_played := false
var pending_move_marker: Node3D = null
var last_direction := Vector2.DOWN

func _ready():
	add_to_group("npcs")
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	
	navigation_agent_3d.path_desired_distance = 0.5
	navigation_agent_3d.target_desired_distance = 0.5
	
	set_physics_process(false)
	await get_tree().physics_frame
	set_physics_process(true)
	
func _physics_process(_delta):
	if is_moving and not navigation_agent_3d.is_navigation_finished():
		var current_location = global_transform.origin
		var next_path_position = navigation_agent_3d.get_next_path_position()
		var new_velocity = (next_path_position - current_location).normalized() * move_speed
		
		if navigation_agent_3d.distance_to_target() > 0.1:
			velocity = new_velocity
			update_animation(velocity)
		else:
			stop_moving()
	else:
		stop_moving()
	move_and_slide()
	
func stop_moving():
	velocity = Vector3.ZERO
	is_moving = false
	play_idle_animation()
	
func get_camera_relative_direction(direction: Vector3) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.ZERO
	
	var cam_forward = -camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x
	
	var dir_2d = Vector2(
		direction.dot(cam_right),
		direction.dot(cam_forward)
	)
	
	return dir_2d.normalized()
	
func update_animation(direction: Vector3):
	var dir_2d = get_camera_relative_direction(direction)
	last_direction = dir_2d
	
	if abs(dir_2d.x) > abs(dir_2d.y):
		animated_sprite_3d.play("walk_side")
		animated_sprite_3d.flip_h = dir_2d.x < 0
	else:
		if dir_2d.y > 0:
			animated_sprite_3d.play("walk_back")
		else:
			animated_sprite_3d.play("walk_front")
			
			
func play_idle_animation():
	if abs(last_direction.x) > abs(last_direction.y):
		animated_sprite_3d.play("idle_side")
		animated_sprite_3d.flip_h = last_direction.x < 0
	else:
		if last_direction.y > 0:
			animated_sprite_3d.play("idle_front")
		else:
			animated_sprite_3d.play("idle_back")
			
			
			
func move_after_dialogue(marker: Node3D):
	pending_move_marker = marker
	
func move_to_marker(marker: Node3D):
	if marker == null:
		return
	navigation_agent_3d.target_position = marker.global_transform.origin
	is_moving = true
	
func _on_dialogue_finished():
	if pending_move_marker:
		move_to_marker(pending_move_marker)
		pending_move_marker = null
		
		
		
func enter_dialogue(target: Node3D) -> void:
	in_dialogue = true
	dialogue_target = target
	
func exit_dialogue() -> void:
	in_dialogue = false
	dialogue_target = null
	
func interact():
	if DialogueManager.is_active or is_moving:
		return
		
		
	var npc_body = self
	var q1 = QuestManager.quests.get("Teary Fields")
	var q2 = QuestManager.quests.get("Green Waters")
	var q3 = QuestManager.quests.get("Red Hot Chilli Pepper")
	
	if (q3 and q3.state == Quest.QuestState.STARTED) or (q2 and q2.state == Quest.QuestState.COMPLETED):
		var dialogue = preload("res://Dialogue/Repeat goodluck.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		return
	
	#Initial Dialogue
	if not has_talked:
		has_talked = true
		QuestManager.finish_quest("Crazy Introductions")
		QuestManager.start_quest("Teary Fields")
		if InventoryManager.has_item("Wrench"):
			QuestManager.set_objective_index("Teary Fields", 1)
		DialogueManager.start_dialogue(initial_dialogue, npc_body)
		return
		
	#Quest 1
	if q1 and q1.state == Quest.QuestState.STARTED:
		if InventoryManager.has_item("Wrench"):
			village_block.disabled = true
			var dialogue = preload("res://Dialogue/Found_Wrench.tres")
			DialogueManager.start_dialogue(dialogue, npc_body)
			QuestManager.finish_quest("Teary Fields")
			move_after_dialogue(point_a)
			return 
		else:
			var dialogue = preload("res://Dialogue/Missing_Wrench.tres")
			DialogueManager.start_dialogue(dialogue, npc_body)
			return
			
	#Quest 2
	if q2 and q2.state == Quest.QuestState.STARTED:
		var parts = InventoryManager.get_item_count("MachinePart")
		
		if q2.current_objective_index == 0:
			var dialogue1 = preload("res://Dialogue/Stolen_Parts.tres")
			DialogueManager.start_dialogue(dialogue1, npc_body)
			QuestManager.set_objective_index("Green Waters", 1)
			return
			
		if parts >= 2 and not found_two_played:
			pumpkin_area_block.disabled = true
			
			
			var dialogue2 = preload("res://Dialogue/Found_Two.tres")
			DialogueManager.start_dialogue(dialogue2, npc_body)
			found_two_played = true
			QuestManager.set_objective_index("Green Waters", 2)
			move_after_dialogue(point_b)
			return
			
		if found_two_played and parts < 3:
			var dialogue3 = preload("res://Dialogue/Find_Villagers.tres")
			DialogueManager.start_dialogue(dialogue3, npc_body)
			return
		
		# When player finds three parts
		if parts >= 3:
			ogre.go_there()
			boss_area_block.disabled = true
			big_fog.material.density = 0.0
			pond.material_override = clean_water
			machine.play("on")
			
			var dialogue4 = preload("res://Dialogue/Final_Found.tres")
			DialogueManager.start_dialogue(dialogue4, npc_body)
			QuestManager.finish_quest("Green Waters")
			InventoryManager.add_item("water", 1)
			return
		
		var dialogue = preload("res://Dialogue/Missing_Parts.tres")
		DialogueManager.start_dialogue(dialogue, npc_body)
		return
		
	DialogueManager.start_dialogue(initial_dialogue, npc_body)
	
func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		interact()
		
func _on_interact_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		interact_icon.toggle_visibility()
		player_in_range = true
	
func _on_interact_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		interact_icon.toggle_visibility()
		player_in_range = false
