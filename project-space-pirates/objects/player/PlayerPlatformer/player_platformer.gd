class_name Player
extends CharacterBody2D

# INFO: This is the player with platformer controls.

@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
var bullet: PackedScene = preload("res://objects/player/PlayerPlatformer/player_bullet.tscn")
var is_dying: bool = false


func _ready() -> void:
	# Grabs the health in player_variables and replaces the placeholder in string (and formats it into an floored int).
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	# Alternative with same result:
	# $CanvasLayer/HealthLabel.text = "HP: " + str(int(PlayerVariables.health))
	
	SceneManager.respawn_location = global_position
	print("SceneManager: Set initial respawn point to ", SceneManager.respawn_location)


func _physics_process(delta: float) -> void:
	if is_dying == true: # Locks Player controls (including gravity).
		return #Do not run any further code if true.
	
	# NOTE: Debug "K" key sets player health to 0. For debugging death-related events.
	if Input.is_action_just_pressed("debug"):
		PlayerVariables.health = 0
		take_damage(0)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	if Input.is_action_just_pressed("shoot"):
		shoot()

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed) # Moves toward a destination speed before stopping.
	
	# Movement.
	face_direction()
	move_and_slide()
	
	# Ammo reloading state.
	if PlayerVariables.is_reloading == true:
		if PlayerVariables.ammo < 6:
			$CanvasLayer/ReloadingLabel.visible = true
			reloading(delta) # Reloads roughly one bullet per second.
			if PlayerVariables.ammo >= 6:
				# TODO: Uncomment the following line once debug is finished.
				$CanvasLayer/ReloadingLabel.visible = false
				PlayerVariables.reloading_progress = 0
				PlayerVariables.is_reloading = false


# Animate Player
func face_direction() -> void:
	if velocity.x < 0:
		$TestSprite2D.flip_h = true
		$MuzzleMarker.position = Vector2(-18, 2) # Face player muzzle to the left.
		$MuzzleMarker.rotation_degrees = 180 # Sets the player muzzle to a rotation of 180 degrees.
	if velocity.x > 0:
		$TestSprite2D.flip_h = false
		$MuzzleMarker.position = Vector2(18, 2) # Face player muzzle to the right (default).
		$MuzzleMarker.rotation_degrees = 0 # Sets the player muzzle back to its original rotation.


func shoot() -> void:
	# Creates bullet and shoots it out of muzzle.
	if $ShootCooldownTimer.is_stopped() and PlayerVariables.ammo >= 1:
		$ShootCooldownTimer.start() # Cooldown timer between shots.
		red_text_blink($CanvasLayer/AmmoLabel)
		PlayerVariables.ammo -= 1
		$CanvasLayer/AmmoLabel.text = "Ammo: %d" % PlayerVariables.ammo
		var b = bullet.instantiate()
		owner.add_child(b) # Adds bullet to the root node of the scene the player is in, instead of to player themself.
		b.transform = $MuzzleMarker.global_transform
		
		$RechargeTimer.start() # Refreshes the recharge timer if it is running, otherwise starts it.
		
		# Stops reloading if it is already occurring.
		if PlayerVariables.is_reloading == true:
			PlayerVariables.is_reloading = false
			$CanvasLayer/ReloadingLabel.visible = false
			PlayerVariables.reloading_progress = 0
			# TODO: The line below might be redundant and unnecessary.
			$CanvasLayer/ReloadingLabel.text = "Recharging... %d%%" % PlayerVariables.reloading_progress


func take_damage(damage: float) -> void:
	# TODO: Add sound effects.
	PlayerVariables.health -= damage
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	print("Player took %d damage!" % damage, " Current HP: ", PlayerVariables.health)
	# TODO Add knockback function here.
	if PlayerVariables.health <= 0 and not is_dying:
		death()
		print("Player is playing dying animations.")


func restore_health(health) -> void:
	# TODO: Add sound effects.
	PlayerVariables.health += health
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	green_text_blink($CanvasLayer/HealthLabel)
	print("Player HP restored by %d" % health)
	print("Current Player HP: ", PlayerVariables.health)


func reloading(delta) -> void:
	if PlayerVariables.reloading_progress >= 100:
		PlayerVariables.ammo += 3
		PlayerVariables.ammo = clampi(PlayerVariables.ammo, 0, 6)
		$CanvasLayer/AmmoLabel.text = "Ammo: %d" % PlayerVariables.ammo
		green_text_blink($CanvasLayer/AmmoLabel)
		PlayerVariables.reloading_progress = 0
	else:
		PlayerVariables.reloading_progress += 100 * delta
		$CanvasLayer/ReloadingLabel.text = "Recharging... %d%%" % PlayerVariables.reloading_progress


func _on_recharge_timer_timeout() -> void:
	PlayerVariables.is_reloading = true


func red_text_blink(label: Control) -> void:
	label.label_settings.font_color = Color(1, 0, 0) # Red font color.
	await get_tree().create_timer(0.2).timeout
	label.label_settings.font_color = Color(1, 1, 1) # White font color.


func green_text_blink(label: Control) -> void:
	label.label_settings.font_color = Color(0, 1, 0) # Red font color.
	await get_tree().create_timer(0.2).timeout
	label.label_settings.font_color = Color(1, 1, 1) # White font color.


func death() -> void:
	is_dying = true
	# TODO: insert animations on this very line.
	await get_tree().create_timer(3).timeout
	global_position = SceneManager.respawn_location # Sets Player position to respawn location.
	
	# Resets health and ammo.
	PlayerVariables.health = 100
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	green_text_blink($CanvasLayer/HealthLabel)
	PlayerVariables.ammo = 3
	$CanvasLayer/AmmoLabel.text = "Ammo: %d" % PlayerVariables.ammo
	green_text_blink($CanvasLayer/AmmoLabel)
	
	print("Player has died.")
	is_dying = false
