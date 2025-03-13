extends Control

@onready var label: Label = $"Label"
@onready var key: Label = $Key

@export var action: String

var event_list: Array

func _ready() -> void:
	update_event_list()

func get_event_list() -> Array:
	var list := []
	
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			list.append(event.as_text_physical_keycode())
	
	return list

func update_event_list() -> void:
	event_list = get_event_list()
	key.text = "[" + ", ".join(event_list) + "]"

func reset_event_list() -> void:
	pass
	update_event_list()

func add_input() -> void:
	pass
