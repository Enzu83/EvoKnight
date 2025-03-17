extends Area2D

@onready var winged_golden_strawberry: Area2D = $WingedGoldenStrawberry

func _on_body_entered(_body: Node2D) -> void:
	winged_golden_strawberry.flee = true
