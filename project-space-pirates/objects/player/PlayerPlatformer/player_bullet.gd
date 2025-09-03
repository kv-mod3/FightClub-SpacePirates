extends Area2D


const SPEED: float = 650
const DAMAGE: float = 10


func _physics_process(delta: float) -> void:
	# Bullet moves right by default.
	position += transform.x * SPEED * delta


# Deletes the bullet after it exits the screen.
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# await get_tree().create_timer(3).timeout # Waits until timeout, then resumes the rest of the code.
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		# TODO: There probably should be a check here to make sure an enemy has the method.
		# Checks if bullet is moving in the direction of right or left.
		if rotation_degrees == 0:
			body.take_damage(DAMAGE, "right")
		if rotation_degrees == -180:
			body.take_damage(DAMAGE, "left")
			# print("Bullet's rotation was in %d degrees." % rotation_degrees)
		queue_free() # Deletes bullet on collision.
	if body.is_in_group("solids"):
		queue_free()
	if body.is_in_group("doors"):
		body.open()
		queue_free()
