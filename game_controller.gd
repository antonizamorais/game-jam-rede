extends Node2D

@export var projectile_scene: PackedScene
@export var launch_speed_scale: float = 6.0   # não usado no cálculo de força, mantido por compatibilidade
@export var reset_delay: float = 0.2

@export_group("Projectile Physics")
@export var mass: float = 1.0
@export var gravity: float = 980.0
@export var force_scale: float = 20.0  

@export_group("Trajectory Preview")
@export var trajectory_time: float = 3.0
@export var sample_step: float = 0.05
@export var trajectory_width: float = 2.0

@onready var aim_pivot: Node2D = $AimPivot
@onready var aim_anim: AnimationPlayer = $AimPivot/AnimationPlayer
@onready var launch_point: Marker2D = $AimPivot/LaunchPoint
@onready var power_bar: Range = $PowerBar
@onready var power_anim: AnimationPlayer = $PowerBar/AnimationPlayer

enum State { AIMING, CHARGING, LOCKED }
var state: State = State.AIMING

func _ready() -> void:
	aim_anim.play("aim_loop")
	power_bar.value = 0

func _process(_delta: float) -> void:
	# Redesenha a curva todo frame enquanto carrega (a força muda a cada frame).
	# Quando sai do CHARGING, redesenha uma última vez pra "apagar" a curva.
	if state == State.CHARGING or _was_charging:
		queue_redraw()
	_was_charging = (state == State.CHARGING)

var _was_charging: bool = false

func _draw() -> void:
	if state != State.CHARGING:
		return

	var force: float = power_bar.value * force_scale
	var angle_rad: float = -aim_pivot.rotation   
	var v0: Vector2 = (force / mass) * Vector2(cos(angle_rad), -sin(angle_rad))
	var gravity_vec: Vector2 = Vector2(0.0, gravity)

	var p0_local: Vector2 = to_local(launch_point.global_position)

	var points: PackedVector2Array = PackedVector2Array()
	var t: float = 0.0
	while t <= trajectory_time:
		var offset: Vector2 = v0 * t + 0.5 * gravity_vec * t * t
		points.append(p0_local + offset)
		if t > 0.1 and offset.y >= 0.0:
			break
		t += sample_step

	if points.size() >= 2:
		draw_polyline(points, Color.WHITE, trajectory_width)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("launch_button"):
		_start_charge()
	elif event.is_action_released("launch_button"):
		_release_launch()

func _start_charge() -> void:
	if state != State.AIMING:
		return
	aim_anim.speed_scale = 0.0
	power_bar.value = 0
	power_anim.play("power_loop")
	state = State.CHARGING

func _release_launch() -> void:
	if state != State.CHARGING:
		return
	var power: float = power_bar.value  
	power_anim.stop()
	state = State.LOCKED
	_launch_projectile(power)

func _launch_projectile(power: float) -> void:
	if projectile_scene == null:
		push_warning("Nenhuma projectile_scene atribuída.")
		_reset_aim()
		return

	var projectile: Node = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var angle_deg: float = -rad_to_deg(aim_pivot.rotation)
	var force: float = power * force_scale

	projectile.launch(launch_point.global_position, force, mass, angle_deg, gravity)

	await get_tree().create_timer(reset_delay).timeout
	_reset_aim()

func _reset_aim() -> void:
	aim_pivot.rotation = 0.0
	aim_anim.speed_scale = 1.0
	power_bar.value = 0
	state = State.AIMING
