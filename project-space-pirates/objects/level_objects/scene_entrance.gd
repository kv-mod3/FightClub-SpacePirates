extends Area2D

@export var next_scene: String


func _on_body_entered(body: Node2D) -> void:
	# Checks if the body entered is a Player, and also if a value is being held by next_scene.
	if body is Player and next_scene:
		get_tree().change_scene_to_file.call_deferred(next_scene)
