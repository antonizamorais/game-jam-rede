extends Area2D

@export var force: float = 1000.0
@export var mass: float = 1.0
@export var angle_deg: float = 45.0
@export var gravity_value: float = 980.0

var p0: Vector2 = Vector2.ZERO
var v0: Vector2 = Vector2.ZERO
var elapsed: float = 0.0
var flying: bool = false

func launch(from_position: Vector2, shoot_force: float, projectile_mass: float, shoot_angle_deg: float, grav: float) -> void:
	force = shoot_force
	mass = projectile_mass
	angle_deg = shoot_angle_deg
	gravity_value = grav

	p0 = from_position
	global_position = p0
	elapsed = 0.0

	var angle_rad: float = deg_to_rad(angle_deg)
	# v0 = (J/m) * (cos θ, -sin θ)
	# y negativo porque no Godot o eixo Y positivo aponta pra baixo.
	v0 = (force / mass) * Vector2(cos(angle_rad), -sin(angle_rad))

	flying = true
	set_physics_process(true)
	
func _physics_process(delta: float) -> void:
	if not flying:
		return

	elapsed += delta

	# p(t) = p0 + v0*t + 0.5*a*t^2  (a = (0, gravity))
	var gravity_term: Vector2 = 0.5 * Vector2(0.0, gravity_value) * elapsed * elapsed
	global_position = p0 + v0 * elapsed + gravity_term

	# girar o sprite acompanhando a direção da velocidade atual
	var current_velocity: Vector2 = v0 + Vector2(0.0, gravity_value) * elapsed
	rotation = current_velocity.angle()

	if global_position.y >= p0.y and elapsed > 0.1:
		_stop_projectile()
		
func _on_body_entered(_body: Node2D) -> void:
	_stop_projectile()

func _on_area_entered(area: Area2D) -> void:
	_stop_projectile()

# Função central para congelar o projétil exatamente onde ele colidiu
func _stop_projectile() -> void:
	flying = false
	set_physics_process(false)
