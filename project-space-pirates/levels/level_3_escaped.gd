extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundManager.play_bgm("victory")
	$AnimationPlayer.play("message")
	await get_tree().create_timer(10).timeout
	get_tree().change_scene_to_file("res://levels/title_menu.tscn")
