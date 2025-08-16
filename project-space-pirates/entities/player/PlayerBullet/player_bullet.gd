extends Area2D

# TODO: Make bullets fire left.
# TODO: Bullets collide with environment.

const SPEED: float = 750


func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	position += transform.x * SPEED * delta
	
	# If Player is facing left, shoot left, and vice versa.
	# if Player.velocity.x < 0:
		# position -= transform.x * SPEED * delta
	# if Player.velocity.x > 0:
		# position += transform.x * SPEED * delta


# Deletes the bullet a few seconds after it exits the screen.
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	await get_tree().create_timer(5).timeout # Waits until timeout, then resumes the rest of the code.
	queue_free()
	print("Bullet deleted.")


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
