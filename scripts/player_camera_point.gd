extends Node2D

@onready var player: Player = $".."
@onready var camera: Camera2D = $Camera

var aimed_position := Vector2.ZERO

func find_aimed_position() -> void:
	aimed_position = player.get_middle_position()
	#if player.sprite.flip_h and player.direction < 0:
		#aimed_position.x = player.position.x - 32
#
	#elif player.direction > 0:
		#aimed_position.x =  player.position.x + 32
		
	aimed_position.y = player.get_middle_position().y - 32

func move_toward_aimed_position(_delta) -> void:
	position = aimed_position

func _ready() -> void:
	position = player.position

func _process(delta: float) -> void:
	find_aimed_position()
	move_toward_aimed_position(delta)
	
