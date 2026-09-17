extends Camera2D


var direction: float = 1.
func _process(delta: float) -> void:
	position.x += delta * direction * 400 # px/s
	if position.x + 1920 >= limit_right:
		direction = -1.
		position.x += limit_right - (position.x + 1920)
	elif position.x <= limit_left:
		direction = 1.
