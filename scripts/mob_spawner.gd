extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var wait_timer: Timer = $WaitTimer

var mob_scene: Resource

var flip_sprite := false
var drop := false
var max_health := 0
var strength := 1
var delay := 0.0

func set_mob(mob_path: String) -> void:
	mob_scene = load(mob_path)

func _ready() -> void:
	wait_timer.start(delay + 0.01)
	
func spawn() -> void:
	var mob: Node2D = mob_scene.instantiate()
	mob.position = position
	mob.flip_sprite = flip_sprite
	mob.drop = drop
	
	if max_health > 0:
		mob.max_health = max_health
		mob.health = max_health
	
	mob.strength = strength
	
	get_parent().add_child(mob)
	
func _on_wait_timer_timeout() -> void:
	animation_player.play("spawning")
