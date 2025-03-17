extends CharacterBody2D

@onready var player: Player = %Player

@onready var activated_point: Node2D = $ActivatedPoint

const SPEED = 400.0

var activated := false

var start_position: Vector2
var activated_position: Vector2

func handle_state() -> void:
	activated = Global.dash_block_activated

func handle_movement(delta: float) -> void:
	if not activated:
		position = position.move_toward(start_position, delta * SPEED)
	else:
		position = position.move_toward(activated_position, delta * SPEED)

func _ready() -> void:
	start_position = position
	activated_position = activated_point.position

func _physics_process(delta: float) -> void:
	handle_state()
	handle_movement(delta)
