extends Area2D

@onready var player: Player = %Player

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPRING_FORCE = 450.0

var direction: Vector2

func spring(body: Node2D) -> void:
	animation_player.stop()
	animation_player.play("spring")
	body.bumped(SPRING_FORCE, direction)

func _ready() -> void:
	# bump up
	if posmod(round(rotation_degrees), 360) == 0:
		direction = Vector2.UP
	# bump right
	elif posmod(round(rotation_degrees), 360) == 90:
		direction = Vector2(1, -0.4)
	# bump down
	elif posmod(round(rotation_degrees), 360) == 180:
		direction = Vector2.DOWN
	# bump left
	elif posmod(round(rotation_degrees), 360) == 270:
		direction = Vector2(-1, -0.4)
	
func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	
	if body == player and body.state != body.State.Fainted:
		spring(body)

func _on_body_entered(body: Node2D) -> void:
	if body == player and body.state != body.State.Fainted:
		spring(body)
