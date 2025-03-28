extends CharacterBody2D

@onready var end_point: Node2D = $EndPoint

@onready var sprite: Sprite2D = $Sprite

@onready var start_light_point: AnimatedSprite2D = $StartLightPoint
@onready var end_light_point: AnimatedSprite2D = $EndLightPoint
@onready var line: Line2D = $Line

@export var speed := 400.0

var activated := false

var start_position: Vector2
var end_position: Vector2

var delta_position: Vector2

func handle_state() -> void:
	activated = Global.dash_block_activated

func handle_movement(delta: float) -> void:
	delta_position = position
	
	if not activated:
		position = position.move_toward(start_position, delta * speed)
	else:
		position = position.move_toward(end_position, delta * speed)
	
	delta_position = position - delta_position

func handle_sprite_offset() -> void:
	# player is one frame late for collision : need to show the previous state of the block
	sprite.position = position - delta_position

func handle_light_point_animation() -> void:
	if not activated:
		end_light_point.frame = 0
	else:
		start_light_point.frame = 0

func _ready() -> void:
	start_position = position
	
	# absolute or relative end position
	if end_point.top_level:
		end_position = end_point.position
	else:
		end_position = start_position + end_point.position
	
	# move light points to their spots
	start_light_point.position = start_position
	end_light_point.position = end_position
	
	# line between the start and end positions
	line.add_point(start_position)
	line.add_point(end_position)

func _physics_process(delta: float) -> void:
	handle_state()
	handle_movement(delta)
	handle_sprite_offset()
	handle_light_point_animation()
