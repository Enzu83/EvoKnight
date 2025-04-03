class_name SwitchCoin
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var activate_sound: AudioStreamPlayer = $ActivateSound

var activated := false

@export var global_switch_coin := -1 # -1 means its not global

func _ready() -> void:
	if global_switch_coin != -1 and Global.collected_switch_coins[global_switch_coin]:
		activated = true
		animated_sprite.play("activated")

func activate() -> void:
	if not activated:
		activated = true
		animated_sprite.play("activated")
		activate_sound.play()
		
		if global_switch_coin != -1:
			Global.collected_switch_coins[global_switch_coin] = true

func _on_body_entered(_body: Node2D) -> void:
	activate()

func _on_area_entered(_area: Area2D) -> void:
	activate()
