extends Area2D

@onready var player: Player = %Player

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const BUMP_FORCE = 500.0
const STRENGTH = 3

var fire: bool # fire: damage, no fire: bump

func _ready() -> void:
	fire = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("magic_slash"):
		fire = !fire
		
		if fire:
			animation_player.play("idle_fire")
		else:
			animation_player.play("idle")

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	
	if body == player:
		# bump
		if not fire:
			# get the direction vector
			print(body.position + area.position)
			print(position)
			print()
			var direction: Vector2 = (body.position + area.position - position).normalized()

			body.bumped(BUMP_FORCE, direction)
			animation_player.play("bumped")
		
		
		elif body.is_hurtable():
			body.hurt(STRENGTH)
			animation_player.play("bumped_fire")

func play_idle_animation() -> void:
	animation_player.play("idle")

func play_idle_fire_animation() -> void:
	animation_player.play("idle_fire")
