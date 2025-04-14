extends CanvasLayer

@onready var label: Label = $Label
@onready var duration_timer: Timer = $DurationTimer
@onready var pick_sound: AudioStreamPlayer = $PickSound

@onready var player: Sprite2D = $Sprites/Player
@onready var magic_slash: Sprite2D = $Sprites/MagicSlash
@onready var charged_slash_effect: Sprite2D = $Sprites/ChargedSlashEffect
@onready var basic_slash: Sprite2D = $Sprites/BasicSlash
@onready var shield: Sprite2D = $Sprites/Shield

var state := 0

func _physics_process(_delta: float) -> void:
	# close the text
	if state == 1 \
	and (Input.is_action_just_pressed("confirm") \
	or Input.is_action_just_pressed("basic_slash") \
	or Input.is_action_just_pressed("dash") \
	or Input.is_action_just_pressed("magic_slash")):
		stop()
	
func start(upgrade: int) -> void:
	state = 0
	pick_sound.play()
	duration_timer.start()
	visible = true
	player.visible = true
	
	player.texture = Global.player_sprite
	magic_slash.texture = Global.magic_slash_sprite
	charged_slash_effect.texture = Global.charged_slash_effect_sprite
	basic_slash.texture = Global.basic_slash_sprite
	shield.modulate = Global.colors[Global.player_color]
	
	label.text = ""
	
	# mana upgrade
	if upgrade == 0:
		player.position = Vector2.ZERO
		player.frame = 10
		magic_slash.visible = true
		
		var inputs = "[" + ", ".join(get_event_list("magic_slash").map(func(x): return x.as_text_physical_keycode())) + "]"

		label.text += "- Unlocked: Mana & Magic Spell -\n\n"
		label.text += "You got mana! Press " + inputs + " to use a magic projectile that can go through walls."
	
	# charged slash upgrade
	elif upgrade == 1:
		player.position = Vector2.ZERO
		player.frame = 10
		charged_slash_effect.visible = true
		basic_slash.visible = true
		
		var inputs = "[" + ", ".join(get_event_list("basic_slash").map(func(x): return x.as_text_physical_keycode())) + "]"
		
		label.text += "- Unlocked: Charged Slash -\n\n"
		label.text += "You got a new attack! Hold " + inputs + " to charge your slash to use a stronger attack."
	
	# shield upgrade
	elif upgrade == 2:
		player.position = Vector2(24, 0)
		player.frame = 18
		shield.visible = true
		
		var inputs = "[" + ", ".join(get_event_list("down").map(func(x): return x.as_text_physical_keycode())) + "]"
		
		label.text += "- Unlocked: Shield -\n\n"
		label.text += "You got a protection! Hold " + inputs + " to cast a shield that absorbs one attack. It takes mana to keep the shield activated."
	

func stop() -> void:
	state = 0
	pick_sound.stop()
	
	visible = false
	player.visible = false
	magic_slash.visible = false
	charged_slash_effect.visible = false
	basic_slash.visible = false
	shield.visible = false
	duration_timer.stop()
	get_tree().paused = false

func get_event_list(action: String) -> Array:
	var list := []
	
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			list.append(event)
	
	return list

func _on_duration_timer_timeout() -> void:
	state = 1
