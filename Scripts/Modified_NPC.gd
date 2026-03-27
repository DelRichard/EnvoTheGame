extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = %AnimatedSprite3D

func _ready() -> void:
	animated_sprite_3d.play("idle")

func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	move_and_slide()
