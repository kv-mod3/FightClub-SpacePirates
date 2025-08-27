class_name Pickup
extends CharacterBody2D

const HEALTH: float = 60

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()


func _on_touch_area_body_entered(body: Node2D) -> void:
	if body is Player and PlayerVariables.health < 100:
		body.restore_health(HEALTH)
		queue_free()
