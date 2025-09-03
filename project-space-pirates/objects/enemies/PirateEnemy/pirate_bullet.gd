extends Area2D


const SPEED: float = 300
const DAMAGE: float = 10


func _physics_process(delta: float) -> void:
	# Bullet moves right by default.
	position -= transform.x * SPEED * delta


# Deletes the bullet a few seconds after it exits the screen.
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if not body.is_invincible:
			body.knockback(global_position)
			body.take_damage(DAMAGE)
			queue_free() # Deletes bullet on collision.
	if body.is_in_group("solids"):
		queue_free()
