extends CanvasLayer

@onready var health_bar: TextureProgressBar = $Stats/HealthBar
@onready var exp_bar: TextureProgressBar = $Stats/ExpBar

func set_health_bar(value: int) -> void:
	health_bar.value = value

func set_relative_health_bar(value: int) -> void:
	health_bar.value += value

func set_exp_bar(value: int) -> void:
	exp_bar.value = value

func set_relative_exp_bar(value: int) -> void:
	exp_bar.value += value
