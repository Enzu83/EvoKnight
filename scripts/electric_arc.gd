extends StaticBody2D

@onready var player: CharacterBody2D = %Player

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var wall_collider: CollisionShape2D = $WallCollider
@onready var hitbox: CollisionShape2D = $Hitbox/Hitbox

@onready var electric_sound: AudioStreamPlayer = $ElectricSound

var active := false

# normal: enabled <=> active
# opposite: disabled <=> active
var opposite := false

func _process(_delta: float) -> void:
	if Global.electric_arc_enabled:
		active = not opposite
	else:
		active = opposite
	
	update_active_state()

func update_active_state() -> void:
	if active:
		animated_sprite.visible = true
		wall_collider.disabled = false
		hitbox.disabled = false
	else:
		animated_sprite.visible = false
		wall_collider.disabled = true
		hitbox.disabled = true

func _on_hitbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(int(Global.player_max_health / 3.0))
		electric_sound.play()
