extends Node

# NOTE: This is not the best implementation at all.

func play_bgm(track: String) -> void:
	match track:
		"victory":
			$VictoryBGM.play()
