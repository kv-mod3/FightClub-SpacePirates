extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _on_start_button_pressed() -> void:
	# Clears menus and starts intro sequence.
	$Title.visible = false
	$Menus.visible = false
	$PlayerShipActor/AnimationPlayer.play("RESET_shrunk")
	
	# Stops and queues animation to fix visual bugs.
	# $PlayerShipActor/AnimationPlayer.stop()
	# $PlayerShipActor/AnimationPlayer.queue("enlarge")
	
	await get_tree().create_timer(1).timeout
	$PlayerShipActor.visible = true
	$PlayerShipActor/AnimationPlayer.play("enlarge")
	await get_tree().create_timer(1).timeout
	$PlayerShipActor/AnimationPlayer.play("flying")
	
	await get_tree().create_timer(0.5).timeout
	$Landing.visible = true
	await get_tree().create_timer(1.5).timeout
	$Landing/OKButton.visible = true


func _on_ok_button_pressed() -> void:
	$Landing.visible = false
	$PlayerShipActor.speed = 300
	$PlayerShipActor.moving = true
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_controls_button_pressed() -> void:
	# Toggles controls panel
	if $Menus/ControlsPanel.visible:
		$Menus/ControlsPanel.visible = false
	else:
		$Menus/ControlsPanel.visible = true


func _on_credits_button_pressed() -> void:
	# Toggles the credits panels.
	# Hides the other menus and title.
	$Title.visible = false
	$Menus/StartButton.visible = false
	$Menus/ControlsButton.visible = false
	$Menus/ControlsPanel.visible = false # In case the controls panel is open, hide it.
	
	# Code for the button.
	if $Menus/CreditsPanel.visible:
		$Menus/CreditsPanel.visible = false
		$Menus/StartButton.visible = true
		$Menus/ControlsButton.visible = true
		$Title.visible = true
	else:
		$Menus/CreditsPanel.visible = true


func _on_debug_level_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_debug.tscn")
