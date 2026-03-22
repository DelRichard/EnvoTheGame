extends ProgressBar

@onready var damage_bar: ProgressBar = $DamageBar
@onready var timer: Timer = $Timer

var health = 0 : set = _set_health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	
	update_color()
	
	if health < prev_health:
		timer.start()
	else:
		damage_bar.value = health
		


func update_color():
	var percent = health / max_value
	
	var color: Color
	
	if percent > 0.6:
		color = Color.GREEN
	elif percent > 0.3:
		color = Color.YELLOW
	else:
		color = Color.RED
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	
	add_theme_stylebox_override("fill", style)

func init_health(_health):
	health = _health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health

func _on_timer_timeout() -> void:
	damage_bar.value = health
