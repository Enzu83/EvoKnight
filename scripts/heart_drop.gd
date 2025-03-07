extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var despawn_timer: Timer = $DespawnTimer

const SPEED = 100.0
const MAX_FALLING_VELOCITY = 450

var player: CharacterBody2D
var heal_value: int
var despawn: bool

func init(value: int, initial_position: Vector2, initial_velocity: Vector2, will_despawn: bool = false) -> CharacterBody2D:
	heal_value = value
	position = initial_position
	velocity = initial_velocity
	despawn = will_despawn
	return self

func _ready() -> void:
	if despawn:
		despawn_timer.start()

func _physics_process(delta: float) -> void:
	player = Global.player

	if not is_on_floor():
		velocity += get_gravity() * delta
		
		# prevent wrong falling too fast
		if velocity.y > MAX_FALLING_VELOCITY:
			velocity.y = MAX_FALLING_VELOCITY

	velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func pick_up(area: Area2D) -> void:
	var body := area.get_parent() # get the player
	pick_up_body(body)

func pick_up_body(body: CharacterBody2D) -> void:
	if body == player \
	and not body.health == body.max_health \
	and player.state != player.State.Fainted \
	and player.state != player.State.Stop:
		animation_player.play("pickup")
		player.heal(heal_value)

func _on_despawn_timer_timeout() -> void:
	queue_free()
