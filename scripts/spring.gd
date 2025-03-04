extends Area2D

@onready var player: Player = %Player

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: CollisionShape2D = $Hitbox

const SPRING_FORCE = 450.0

var orientation: String
var launch_direction: Vector2

func spring(body: Node2D) -> void:
	animation_player.stop()
	animation_player.play("spring")
	body.bumped(SPRING_FORCE, launch_direction)

func _ready() -> void:
	# bump up
	if posmod(round(rotation_degrees), 360) == 0:
		orientation = "up"
		launch_direction = Vector2.UP
	# bump right
	elif posmod(round(rotation_degrees), 360) == 90:
		orientation = "right"
		launch_direction = Vector2(1, -0.4)
	# bump down
	elif posmod(round(rotation_degrees), 360) == 180:
		orientation = "down"
		launch_direction = Vector2.DOWN
	# bump left
	elif posmod(round(rotation_degrees), 360) == 270:
		orientation = "left"
		launch_direction = Vector2(-1, -0.4)

func _physics_process(_delta: float) -> void:
	# deactivate hitbox if player is behind the spring
	if (orientation == "up" and player.position.y - position.y > 8) \
	or (orientation == "right" and player.position.x - position.x < -8) \
	or (orientation == "down" and player.position.y - position.y < -8) \
	or (orientation == "left" and player.position.x - position.x > 8):
		hitbox.disabled = true
	else:
		hitbox.disabled = false

func check_spring(body: Node2D) -> void:
	if body == player and body.state != body.State.Fainted:
		spring(body)

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	
	check_spring(body)
	
func _on_body_entered(body: Node2D) -> void:
	check_spring(body)
