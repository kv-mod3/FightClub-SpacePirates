extends AnimatableBody2D

var is_opened: bool = false


# Opens door upon being hit by Player bullet.
func open() -> void:
	if not is_opened:
		is_opened = true
		$AudioStreamPlayer2D.play()
		$DoorSensors.color = Color(0.26, 1, 0.26)
		$AnimationPlayer.play("open")
		$CollisionPolygon2D.set_deferred("disabled", true)
