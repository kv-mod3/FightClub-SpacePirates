extends CharacterBody2D

const SPEED = 300.0


func _physics_process(delta: float) -> void:
	# Get the direction and handle the movement/deceleration.
	# Direction is currently set to RIGHT (1, 0).
	var direction := Vector2.RIGHT
	if direction:
		velocity.x = direction.x * SPEED
	else:
		# TODO: lower the deceleration rate.
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
