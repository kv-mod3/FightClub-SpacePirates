extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_debug_level_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_debug.tscn")


func _on_credits_button_pressed() -> void:
	pass # Replace with function body.


# Toggles the controls information label.
func _on_controls_button_pressed() -> void:
	if $CanvasLayer/ControlsLabel.visible:
		$CanvasLayer/ControlsLabel.visible = false
	else:
		$CanvasLayer/ControlsLabel.visible = true
