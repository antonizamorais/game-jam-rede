extends Node2D

@export var gravity: float = 980.0   # px/s² — ajuste ao gosto
@export var max_lifetime: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var _time_alive: float = 0.0

func launch(initial_velocity: Vector2) -> void:
	velocity = initial_velocity
	_time_alive = 0.0
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_time_alive += delta
	velocity.y += gravity * delta
	position += velocity * delta

	# gira o sprite acompanhando a trajetória
	rotation = velocity.angle()

	# saiu da tela ou passou do tempo -> remove
	var vp_rect: Rect2 = get_viewport_rect()
	var out_of_bounds := not vp_rect.grow(200).has_point(get_viewport_transform() * global_position)
	if out_of_bounds or _time_alive > max_lifetime:
		queue_free()

func _on_area_2d_body_entered(_body: Node) -> void:
	queue_free()
