extends Sprite2D

@onready var player: Player = $".."
@onready var charge_sound: AudioStreamPlayer = $ChargeSound

func _ready() -> void:
	texture = Global.charged_slash_effect_sprite

func _physics_process(_delta: float) -> void:
	if player.bigger_slash and player.bigger_slash_count == player.bigger_slash_max:
		if not visible:
			charge_sound.play()
			visible = true
	else:
		visible = false
