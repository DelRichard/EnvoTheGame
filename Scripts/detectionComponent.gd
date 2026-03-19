class_name DetectionComponent extends Node

@onready var head: Node3D = $"../Head"
@onready var ray_cast_3d: RayCast3D = $"../Head/RayCast3D"


@export var horizontal_fov := 150.0
@export var vertical_fov := 120.0  
@export var max_view_distance := 10.0
@export var debug:= true

var player
var player_head

var see_player := false


func _ready():
	player = get_tree().get_first_node_in_group("Player")
	player_head = player.get_node("CameraPivot")


func _physics_process(delta: float) -> void:
	if player and can_see_player() and is_in_fov() and has_line_of_sight():
		if debug:
			print("NPC can see player")
		see_player = true
	else:
		if debug:
			print("NPC cannot see player")
		see_player = false


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
