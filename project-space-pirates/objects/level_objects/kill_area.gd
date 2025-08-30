extends Area2D

const DAMAGE: float = 111

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(DAMAGE)
