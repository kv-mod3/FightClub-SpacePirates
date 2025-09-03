extends CharacterBody2D

var speed: float = 100.0
@export var moving: bool = false

func _physics_process(delta: float) -> void:
	# Get the direction and handle the movement/deceleration.
	# Direction is currently set to RIGHT (1, 0).
	if moving:
		var direction := Vector2.LEFT
		velocity.x = direction.x * speed
		move_and_slide()
