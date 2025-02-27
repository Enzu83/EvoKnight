extends Area2D

@onready var sprite: Sprite2D = $Sprite
@onready var get_sound: AudioStreamPlayer = $GetSound

var red_sprite := preload("res://assets/sprites/items/spr_flag_red.png")
var green_sprite := preload("res://assets/sprites/items/spr_flag_green.png")

func _process(_delta: float) -> void:
	if Global.respawn_position == position:
		sprite.texture = green_sprite
	else:
		sprite.texture = red_sprite

func _on_body_entered(body: Node2D) -> void:
	if body == Global.player and Global.respawn_position != position:
		Global.respawn_position = position
		Global.collect_pending_stars()
		get_sound.play()
