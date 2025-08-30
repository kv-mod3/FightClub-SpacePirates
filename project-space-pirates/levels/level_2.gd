extends Node2D

var countdown: int = 60
var color_increment: float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.start()
	$Control/CanvasLayer/TimerLabel.text = "Time left: %d" % countdown
	SoundManager.play_bgm("level 2")


func _on_timer_timeout() -> void:
	countdown -= 1
	$Control/CanvasLayer/TimerLabel.text = "Time left: %d" % countdown
	# Font color gradually changes to yellow.
	if countdown > 40:
		color_increment -= 0.05
		$Control/CanvasLayer/TimerLabel.label_settings.font_color = Color(1, 1, color_increment)
	# Resets value of variable.
	if countdown == 40:
		color_increment = 1
	# Font color gradually changes to orange, then to red.
	if countdown < 40 and countdown > 1:
		color_increment -= 0.025
		$Control/CanvasLayer/TimerLabel.label_settings.font_color = Color(1, color_increment, 0)
	# Reloads scene if timer is over.
	if countdown <= 0:
		get_tree().reload_current_scene()
