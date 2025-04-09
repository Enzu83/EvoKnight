extends Area2D

@onready var player: Player = %Player

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	Global.add_star_to_total(self)
	
	if Global.is_star_collected(self):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	pick_up_body(body)

func pick_up(area: Area2D) -> void:
	var body := area.get_parent() # get the player
	pick_up_body(body)

func pick_up_body(body: Node2D) -> void:
	if animation_player.current_animation != "pickup" \
	and body == player \
	and player.state != player.State.Fainted \
	and player.state != player.State.Stop:
		Global.add_star_to_pending(self)
		animation_player.play("pickup")
