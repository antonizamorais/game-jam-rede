extends Node2D

@export var projectile_scene: PackedScene
@export var launch_speed_scale: float = 6.0   # converte "power" em velocidade
@export var reset_delay: float = 0.2          # tempo até liberar nova mira

@onready var aim_pivot: Node2D = $AimPivot
@onready var aim_anim: AnimationPlayer = $AimPivot/AnimationPlayer
@onready var launch_point: Marker2D = $AimPivot/LaunchPoint
@onready var power_bar: Range = $PowerBar
@onready var power_anim: AnimationPlayer = $PowerBar/AnimationPlayer

enum State { AIMING, CHARGING, LOCKED }
# Tenho três estados: Mirando, Ângulo Travado, Lançamento
var state: State = State.AIMING

func _ready() -> void:
	aim_anim.play("aim_loop")
	power_bar.value = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("launch_button"):
		_start_charge()
	elif event.is_action_released("launch_button"):
		_release_launch()

func _start_charge() -> void:
	if state != State.AIMING:
		return
	# "Congela" a mira sem resetar a pose atual (não usar stop() puro,
	# porque ele rebobina a animação pro início).
	aim_anim.speed_scale = 0.0

	power_bar.value = 0
	power_anim.play("power_loop")
	state = State.CHARGING

func _release_launch() -> void:
	if state != State.CHARGING:
		return
	power_anim.stop()
	var power: float = power_bar.value  # intensidade travada no instante do soltar
	state = State.LOCKED
	_launch_projectile(power)

func _launch_projectile(power: float) -> void:
	if projectile_scene == null:
		push_warning("Nenhuma projectile_scene atribuída.")
		_reset_aim()
		return

	var projectile: Node2D = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = launch_point.global_position

	var angle: float = aim_pivot.rotation   # ângulo travado
	var speed: float = power * launch_speed_scale
	var velocity: Vector2 = Vector2.RIGHT.rotated(angle) * speed

	projectile.launch(velocity)

	await get_tree().create_timer(reset_delay).timeout
	_reset_aim()

func _reset_aim() -> void:
	aim_pivot.rotation = 0.0
	aim_anim.speed_scale = 1.0
	power_bar.value = 0
	state = State.AIMING
