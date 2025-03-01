extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPEED = 120

var player: CharacterBody2D

func _process(_delta: float) -> void:
	player = Global.player
	
func pick_up(area: Area2D) -> void:
	var body := area.get_parent() # get the player
	pick_up_body(body)

func pick_up_body(body: CharacterBody2D) -> void:
	if body == player \
	and player.state != player.State.Fainted \
	and player.state != player.State.Stop:
		animation_player.play("pickup")
		player.super_speed = true

func _on_area_entered(area: Area2D) -> void:
	pick_up(area)

func _on_body_entered(body: Node2D) -> void:
	pick_up_body(body)
