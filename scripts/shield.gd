extends Sprite2D

@onready var player: Player = $".."

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var activate_sound: AudioStreamPlayer = $ActivateSound
@onready var end_sound: AudioStreamPlayer = $EndSound

var active:= false

func align_with_player() -> void:
	position.y = -15 + (player.wall_collider.position.y + 11)

func activate() -> void:
	if not active:
		active = true
		animation_player.play("active")
		activate_sound.play()

func explode() -> void:
	if active:
		active = false
		animation_player.play("exploded")

func deactivate() -> void:
	if active:
		active = false
		animation_player.play("RESET")
		end_sound.play()

func _ready() -> void:
	modulate = Global.colors[Global.player_color]

func _physics_process(_delta: float) -> void:
	align_with_player()
