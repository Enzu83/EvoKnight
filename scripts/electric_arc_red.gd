extends StaticBody2D

@onready var player: CharacterBody2D = %Player

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var wall_collider: CollisionShape2D = $WallCollider
@onready var hitbox: CollisionShape2D = $Hitbox/Hitbox


var active := false

# normal: enabled <=> active
# opposite: disabled <=> active
var opposite := false


func _ready() -> void:
	# resize electric bar depending on its size
	animated_sprite.play(str(round(scale.y * 5)))
	
	var wall_collider_rect = RectangleShape2D.new()
	wall_collider_rect.size = Vector2(6, 40 * scale.y - 2)
	wall_collider.set_shape(wall_collider_rect)
	
	var hitbox_rect = RectangleShape2D.new()
	hitbox_rect.size = Vector2(8, 40 * scale.y)
	hitbox.set_shape(hitbox_rect)
	
	scale.y = 1

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
		body.fainted()
