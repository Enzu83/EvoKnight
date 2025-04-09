extends Area2D

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: CollisionShape2D = $Hitbox

@export var upgrade: int
@export var target_position: Vector2

var pickable := false

func init(upgrade_: int, target_position_: Vector2) -> Node2D:
	upgrade = upgrade_
	target_position = target_position_
	return self

func _ready() -> void:
	sprite.frame = upgrade

func _physics_process(delta: float) -> void:
	# go the target position
	if not pickable:
		if position != target_position:
			position = position.move_toward(target_position, 150 * delta)
		
		# reached the target
		else:
			pickable = true
			hitbox.disabled = false
			animation_player.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if pickable \
	and body.state != body.State.Fainted \
	and body.state != body.State.Stop:
		animation_player.play("pickup")
		
		# select the correct upgrade
		if upgrade == 0:
			body.magic_slash_enabled = true
			
		elif upgrade == 1:
			body.bigger_slash = true
			
		elif upgrade == 2:
			body.shield_enabled = true
