extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundManager.play_bgm("victory")
	cinematic()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func cinematic() -> void:
	pass
