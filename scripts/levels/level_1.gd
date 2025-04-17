extends Node2D

@onready var hud: CanvasLayer = %HUD
@onready var player: Player = %Player

@onready var controls_info: Label = $ControlsInfo

func _ready() -> void:
	Global.current_level = 1
	Global.player = player
	hud.display_collectable = true
	hud.display_boss = false

	if Global.respawn_position != Vector2.INF:
		player.position = Global.respawn_position
	
	# controls info text
	controls_info.text = ""
	
	var jump_inputs = "[" + ", ".join(get_event_list("jump").map(func(x): return x.as_text_physical_keycode())) + "]"
	var dash_inputs = "[" + ", ".join(get_event_list("dash").map(func(x): return x.as_text_physical_keycode())) + "]"
	var slash_inputs = "[" + ", ".join(get_event_list("basic_slash").map(func(x): return x.as_text_physical_keycode())) + "]"
	
	controls_info.text += "Jump with " + jump_inputs + ".\n"
	controls_info.text += "Jump in the air to perform a double jump.\n\n"
	controls_info.text += "Dash in 8 directions with " + dash_inputs + ".\n\n"
	controls_info.text += "Attack in 4 directions with " + slash_inputs + ".\n\n"

func get_event_list(action: String) -> Array:
	var list := []
	
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			list.append(event)
	
	return list
