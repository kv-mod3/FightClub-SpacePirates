class_name Player
extends CharacterBody2D

# INFO: This is the player with platformer controls.

enum State {
	IDLE,
	BLINK,
	JUMP,
	SHOOT
}

@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
var bullet: PackedScene = preload("res://objects/player/PlayerPlatformer/player_bullet.tscn")
var current_state := State.IDLE
var is_dying: bool = false
var is_invincible: bool = false
var is_knocked_back: bool = false


func _ready() -> void:
	# Grabs the health in player_variables and replaces the placeholder in string (and formats it into an floored int).
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	# Alternative with same result:
	# $CanvasLayer/HealthLabel.text = "HP: " + str(int(PlayerVariables.health))
	$CanvasLayer/AmmoLabel.text = "Ammo: %d" % PlayerVariables.ammo
	
	SceneManager.respawn_location = global_position
	print("SceneManager: Set initial respawn point to ", SceneManager.respawn_location)


func _physics_process(delta: float) -> void:
	if is_dying == true: # Locks Player controls (including gravity).
		return #Do not run any further code if true.
	
	# TESTING: Debug "K" key sets player health to 0. For debugging death-related events.
	if Input.is_action_just_pressed("debug"):
		take_damage(100)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		$Sounds/Jump.play()
		$AnimatedSprite2D.play("jump")
	
	# Shoots if not knocked back.
	if Input.is_action_just_pressed("shoot") and not is_knocked_back:
		shoot()

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("left", "right")
	if direction and not is_knocked_back:
		velocity.x = direction * move_speed
		$AnimatedSprite2D.play("walk")
		face_direction() # Is placed here to prevent knockback from turning Player around.
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed) # Moves toward a destination speed before stopping.
	
	if velocity == Vector2.ZERO:
		$AnimatedSprite2D.play("idle")
	
	# Movement.
	move_and_slide()
	
	# Ammo reloading conditions.
	if PlayerVariables.is_reloading == true:
		if PlayerVariables.ammo < 6:
			$CanvasLayer/ReloadingLabel.visible = true
			reloading(delta) # Reloads roughly one bullet per second.
			if PlayerVariables.ammo >= 6:
				$CanvasLayer/ReloadingLabel.visible = false
				PlayerVariables.reloading_progress = 0
				PlayerVariables.is_reloading = false


func state_controller() -> void:
	match current_state:
		State.IDLE:
			$AnimatedSprite2D.play("idle")
		State.SHOOT:
			$AnimatedSprite2D.play("shoot_air")


# Animate Player
func face_direction() -> void:
	if velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
		$MuzzleMarker.position = Vector2(-21, 1.5) # Face player muzzle to the left.
		$MuzzleMarker.rotation_degrees = 180 # Sets the player muzzle to a rotation of 180 degrees.
	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
		$MuzzleMarker.position = Vector2(21, 1.5) # Face player muzzle to the right (default).
		$MuzzleMarker.rotation_degrees = 0 # Sets the player muzzle back to its original rotation.


func shoot() -> void:
	# Creates bullet and shoots it out of muzzle, as long as weapon is ready and ammo is > 1.
	if $ShootCooldownTimer.is_stopped() and PlayerVariables.ammo >= 1:
		$ShootCooldownTimer.start() # Cooldown timer between shots.
		
		if not is_on_floor():
			$AnimatedSprite2D.play("shoot_air")
		else:
			# BUG: Conflicting with idle animation.
			$AnimatedSprite2D.play("shoot_ground")
		
		# HUD effects.
		red_text_blink($CanvasLayer/AmmoLabel)
		PlayerVariables.ammo -= 1
		$CanvasLayer/AmmoLabel.text = "Ammo: %d" % PlayerVariables.ammo
		
		# Bullet creation.
		var b = bullet.instantiate()
		owner.add_child(b) # Adds bullet to the root node of the scene the player is in, instead of to player themself.
		b.transform = $MuzzleMarker.global_transform
		$Sounds/Shoot.play()
		
		$RechargeTimer.start() # Refreshes the recharge timer if it is running, otherwise starts it.
		
		# Stops reloading if it is already occurring.
		if PlayerVariables.is_reloading == true:
			PlayerVariables.is_reloading = false
			$CanvasLayer/ReloadingLabel.visible = false
			PlayerVariables.reloading_progress = 0
			# TODO: The line below might be redundant and unnecessary.
			$CanvasLayer/ReloadingLabel.text = "Recharging... %d%%" % PlayerVariables.reloading_progress


func take_damage(damage: float) -> void:
	if not is_invincible:
		i_frames(3) # Invincibility frames for x seconds.
		# TODO: Add animations.
		PlayerVariables.health -= damage
		$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
		print("Player took %d damage!" % damage, " Current HP: ", PlayerVariables.health)
		if PlayerVariables.health <= 0 and not is_dying:
			death()
			print("Player is playing dying animations.")
		else:
			$Sounds/Hurt.play()


func knockback(bullet_position) -> void:
	if not is_knocked_back:
		is_knocked_back = true
		var knockback_direction: Vector2 = global_position - bullet_position
		var knockback_strength: float = 200

		print("Bullet direction: ", knockback_direction)
		if knockback_direction.x < 0:
			knockback_direction = Vector2(-800, -200)
		if knockback_direction.x > 0:
			knockback_direction = Vector2(800, -200)
		# Targets the player's velocity and pushes them back in a direction multiplied by strength.
		velocity = knockback_direction
		print("Velocity from hit: ", velocity)
		await get_tree().create_timer(0.3).timeout
		is_knocked_back = false


# Knockback when Player's hitbox touches enemy.
# TODO: Rework above knockback function into the following one.
func _on_hitbox_area_body_entered(body: Node2D) -> void:
	if not is_knocked_back:
		is_knocked_back = true
		if body.is_in_group("enemies"):
			# Takes the player position and subtracts the target's position from it.
			var distance: Vector2 = global_position - body.global_position
			var knockback_direction: Vector2
			var knockback_strength: float = 200
		
			if distance.x < 0:
				knockback_direction = Vector2(-5, -1.5)
			if distance.x > 0:
				knockback_direction = Vector2(5, -1.5)
			# Targets the player's velocity and pushes them back in a direction multiplied by strength.
			velocity = knockback_direction * knockback_strength
			
			take_damage(20)
			await get_tree().create_timer(0.6).timeout
			is_knocked_back = false


# Invincibility period after taking damage.
func i_frames(duration) -> void:
	is_invincible = true
	await get_tree().create_timer(duration).timeout
	is_invincible = false

# NOTE: Currently unused.
func i_frames_effect() -> void:
	$AnimatedSprite2D.visible = false
	await get_tree().create_timer(0.2).timeout
	$AnimatedSprite2D.visible = true
	await get_tree().create_timer(0.2).timeout
	$AnimatedSprite2D.visible = false
	await get_tree().create_timer(0.2).timeout
	$AnimatedSprite2D.visible = true
	await get_tree().create_timer(0.2).timeout
	$AnimatedSprite2D.visible = false
	await get_tree().create_timer(0.2).timeout
	$AnimatedSprite2D.visible = true


func restore_health(health) -> void:
	PlayerVariables.health += health
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	$Sounds/Pickup.play()
	green_text_blink($CanvasLayer/HealthLabel)
	print("Player HP restored by %d" % health)
	print("Current Player HP: ", PlayerVariables.health)


func reloading(delta) -> void:
	if PlayerVariables.reloading_progress >= 100:
		PlayerVariables.ammo += 3
		PlayerVariables.ammo = clampi(PlayerVariables.ammo, 0, 6)
		$CanvasLayer/AmmoLabel.text = "Ammo: %d" % PlayerVariables.ammo
		green_text_blink($CanvasLayer/AmmoLabel)
		$Sounds/FinishRecharge.play()
		PlayerVariables.reloading_progress = 0
	else:
		PlayerVariables.reloading_progress += 100 * delta
		$CanvasLayer/ReloadingLabel.text = "Recharging... %d%%" % PlayerVariables.reloading_progress


func _on_recharge_timer_timeout() -> void:
	PlayerVariables.is_reloading = true
	$Sounds/Recharging.play()


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
	$Sounds/Death.play()
	# TODO: insert animations on this very line.
	await get_tree().create_timer(3).timeout
	global_position = SceneManager.respawn_location # Sets Player position to respawn location.
	
	# Resets health and ammo.
	PlayerVariables.health = 100
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	green_text_blink($CanvasLayer/HealthLabel)
	PlayerVariables.ammo = 6
	$CanvasLayer/AmmoLabel.text = "Ammo: %d" % PlayerVariables.ammo
	green_text_blink($CanvasLayer/AmmoLabel)
	
	print("Player has died.")
	is_dying = false
