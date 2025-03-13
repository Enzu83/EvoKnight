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
			list.append(event)
	
	return list

func update_event_list() -> void:
	event_list = get_event_list()
	
	# get the string label of each event in the list
	key.text = "[" + ", ".join(event_list.map(func(x): return x.as_text_physical_keycode())) + "]"

func reset_event_list() -> void:
	InputMap.action_erase_events(action)
	update_event_list()

func add_input(event: InputEventKey) -> bool:
	if event_list.map(func(x): return x.unicode).has(event.unicode):
		return false
	
	if event_list.size() < 4:
		InputMap.action_add_event(action, event)
	else:
		# erase first event
		InputMap.action_erase_event(action, event_list[0])
		event_list.pop_front()
		
		# add the new event
		InputMap.action_add_event(action, event)
		event_list.append(event)
	
	update_event_list()
	
	return true
