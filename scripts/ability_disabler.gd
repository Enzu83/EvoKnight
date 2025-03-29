extends Area2D

@onready var player: Player = %Player

@onready var sprite: Sprite2D = $Sprite
@onready var particles: Sprite2D = $Particles

@onready var hitbox: CollisionShape2D = $Hitbox

@onready var trigger_sound: AudioStreamPlayer = $TriggerSound

@export var disable := true

func _ready() -> void:
	if disable:
		sprite.modulate = Color(100 / 255.0, 100 / 255.0, 100 / 255.0, 0.8)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.6)
	
	sprite.region_rect.size = 16 * Vector2(1, scale.y)
	particles.region_rect.size = 16 * Vector2(9, scale.y)
	
	var hitbox_rect = RectangleShape2D.new()
	hitbox_rect.size = 16 * Vector2(1, scale.y)
	hitbox.set_shape(hitbox_rect)
	
	scale.y = 1

func apply_effect(body) -> void:
	if body.ability_disabled != disable:
		trigger_sound.play()
		
		body.dash_enabled = !disable
		body.mana_enabled = !disable
		body.ability_disabled = disable
		
		if disable:
			Global.set_player_color("dark", true)
		else:
			Global.set_player_color(Global.player_color)
		
		player.update_sprite()

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	apply_effect(body)

func _on_body_entered(body: Node2D) -> void:
	apply_effect(body)
