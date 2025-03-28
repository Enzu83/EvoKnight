extends Area2D

@onready var player: Player = %Player

@onready var parent_handler: Area2D = $".."

@onready var sprite: Sprite2D = $Sprite
@onready var trigger_sound: AudioStreamPlayer = $TriggerSound

@export var disable := true

var default_disable: bool
var default_color: Color

func apply_effect(body) -> void:
	if disable:
		parent_handler.disable_all() # transform every ability mystery to disabler
		
	reveal()
	
	if body.ability_disabled != disable:
		trigger_sound.play()
			
		body.dash_enabled = !disable
		body.mana_enabled = !disable
		body.ability_disabled = disable
		player.update_sprite()

func reveal() -> void:
	if disable:
		Global.set_player_color("dark", true)
		sprite.modulate = Color(100 / 255.0, 100 / 255.0, 100 / 255.0, 0.8)
	else:
		Global.set_player_color(Global.player_color)
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.6)

func reset() -> void:
	disable = default_disable
	sprite.modulate = default_color

func _ready() -> void:
	default_disable = disable
	default_color = sprite.modulate

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	apply_effect(body)

func _on_body_entered(body: Node2D) -> void:
	apply_effect(body)
