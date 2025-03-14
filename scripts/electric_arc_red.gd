extends StaticBody2D

@onready var player: CharacterBody2D = %Player

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var solid_hitbox_sprite: Sprite2D = $AnimatedSprite/SolidHitboxSprite

@onready var wall_collider: CollisionShape2D = $WallCollider
@onready var hitbox: CollisionShape2D = $Hitbox/Hitbox


var active := false

# normal: enabled <=> active
# opposite: disabled <=> active
@export var reversed := false
@export var solid := true


func _ready() -> void:
	# resize electric bar depending on its size
	animated_sprite.play(str(round(scale.y * 5)))
	
	var wall_collider_rect = RectangleShape2D.new()
	wall_collider_rect.size = Vector2(6, 40 * scale.y - 2)
	wall_collider.set_shape(wall_collider_rect)
	
	var hitbox_rect = RectangleShape2D.new()
	hitbox_rect.size = Vector2(8, 40 * scale.y)
	hitbox.set_shape(hitbox_rect)
	
	# update solid hitbox sprite size
	solid_hitbox_sprite.scale.y = 40 * scale.y;
	
	scale.y = 1
	
	# solid hitbox or not
	if not solid:
		wall_collider.disabled = true
		solid_hitbox_sprite.visible = false

func _process(_delta: float) -> void:
	if Global.electric_arc_enabled:
		active = not reversed
	else:
		active = reversed
	
	update_active_state()

func update_active_state() -> void:
	if active:
		animated_sprite.visible = true
		hitbox.disabled = false
		
		if solid:
			wall_collider.disabled = false
			solid_hitbox_sprite.visible = true
	else:
		animated_sprite.visible = false
		hitbox.disabled = true
		
		if solid:
			wall_collider.disabled = true
			solid_hitbox_sprite.visible = false

func _on_hitbox_area_entered(area: Area2D) -> void:
	var body := area.get_parent() # get the player

	# hurt the player
	if body == player and player.is_hurtable():
		body.fainted()
