extends Node

# NOTE: This is not the best implementation at all.

func play_bgm(level: String) -> void:
	match level:
		"level 1":
			$Level1BGM.play()
		"level 2":
			$Level2BGM.play()
		"level 3":
			$Level3BGM.play()
