extends StaticBody2D

@onready var player: CharacterBody2D = %Player

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var wall_collider: CollisionShape2D = $WallCollider
@onready var hitbox: CollisionShape2D = $Hitbox/Hitbox

@onready var electric_sound: AudioStreamPlayer = $ElectricSound

var active := false

# normal: enabled <=> active
# opposite: disabled <=> active
@export var reversed := false
@export var solid := true

func _ready() -> void:
	# solid hitbox or not
	if not solid:
		wall_collider.disabled = true

func _process(_delta: float) -> void:
	if Global.electric_arc_enabled:
		active = not reversed
	else:
		active = reversed
	
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
		body.hurt(ceil(Global.player_max_health / 4.0), true)
		electric_sound.play()
