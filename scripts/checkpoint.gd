extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var get_sound: AudioStreamPlayer = $GetSound

enum Anim {red, green, yellow}
var anim: Anim

func play_animation(anim_name: String) -> void:
	# play the animation if it's not the current one
	if anim != Anim.get(anim_name):
		animation_player.play(anim_name)
		anim = Anim.get(anim_name)

func _physics_process(_delta: float) -> void:
	if Global.respawn_position != position:
		play_animation("red")
	elif Global.get_pending_stars() > 0:
		play_animation("yellow")
	else:
		play_animation("green")

func collect_checkpoint() -> void:
	if Global.respawn_position != position \
	or Global.get_pending_stars() > 0:
		Global.respawn_position = position
		Global.collect_pending_stars()
		get_sound.play()

func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		collect_checkpoint()

func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	
	if body == Global.player:
		collect_checkpoint()
