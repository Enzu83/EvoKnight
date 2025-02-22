extends StaticBody2D

@onready var player: CharacterBody2D = %Player
@onready var sprite: Sprite2D = $Sprite

@onready var wall_collider: CollisionShape2D = $WallCollider
@onready var hitbox: CollisionShape2D = $Hitbox/Hitbox

@onready var clang_sound: AudioStreamPlayer = $ClangSound

func _ready() -> void:
	add_to_group("enemies")
	
	# resize sprite and collision shapes
	sprite.region_rect.size = 8 * Vector2(abs(scale.x), 1)
	
	var wall_collider_rect = RectangleShape2D.new()
	wall_collider_rect.size = Vector2(8 * abs(scale.x), 4)
	wall_collider.set_shape(wall_collider_rect)
	
	var hitbox_rect = RectangleShape2D.new()
	hitbox_rect.size = Vector2(8 * abs(scale.x) + 0.1, 4.1)
	hitbox.set_shape(hitbox_rect)
	
	scale.x = sign(scale.x)

# spike don't get hurt
func hurt(_damage: int, _attack: Area2D) -> bool:
	clang_sound.play()
	return false

func _on_hitbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.hurt(int(Global.player_max_health / 3.0))
