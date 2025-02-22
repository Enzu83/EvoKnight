extends Area2D

@onready var big_bat: Area2D = $BigBat
@onready var fight_trigger: CollisionShape2D = $FightTrigger
@onready var start_timer: Timer = $StartTimer

@onready var player: Player = %Player
@onready var camera: Camera2D = %Camera

func _on_body_entered(body: Node2D) -> void:
	if body == player \
	and big_bat.state == big_bat.State.Sleep:
		camera.limit_bottom = -216
		start_timer.start()
		player.state = player.State.Stop
		player.velocity.x = 0
		player.direction = 0
		

func _on_start_timer_timeout() -> void:
	big_bat.animation_player.play("wake_up")
