extends Area2D

var is_activated: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_activated:
		is_activated = true
		SceneManager.respawn_location = $RespawnMarker.global_position
		print("SceneManager: Saved respawn location at ", SceneManager.respawn_location)
