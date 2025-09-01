extends CharacterBody2D

enum State {
	INACTIVE,
	IDLE,
	CHASE,
	JUMP,
	SHOOT
}

var health: float = 100
var move_speed: float = 30
var acceleration: float = 5 # How quickly the node accelerates to target velocity.
var jump_velocity: float = -400 # The boss will adjust jump velocity depending on behavior.
var bullet: PackedScene = preload("res://objects/enemies/BossEnemy/boss_bullet.tscn")

var current_state := State.INACTIVE
var possible_states: Array = [State.CHASE, State.JUMP]
var direction: Vector2
var target: Node2D # Starts with a value of null on load. Currently unused.
var is_shooting: bool = false
var is_hovering: bool = false
var taking_damage: bool = false
var is_invincible: bool = true # Is invincible at the start to prevent cheese.


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	# Player affected by gravity if not on floor or hovering.
	if not is_on_floor() and not is_hovering:
		velocity += get_gravity() * delta
	# if is_on_floor(): # WARNING: Breaks the jump behavior if enabled.
	state_controller()
	move_and_slide()


func state_controller() -> void:
	match current_state:
		State.INACTIVE:
			pass
		State.IDLE:
			pass
		State.CHASE:
			move()
			face_target()
		State.JUMP:
			jump_attack()
			current_state = State.CHASE
		State.SHOOT:
			face_target()
			if not is_shooting:
				await charging_shot()
				$AnimatedSprite2D.play("moving")
				current_state = State.CHASE


func move() -> void:
	# velocity = velocity.move_toward(direction * move_speed, acceleration)
	if current_state == State.CHASE:
		var dir_to_player = position.direction_to(target.position) * move_speed
		velocity.x = dir_to_player.x


func jump() -> void:
	jump_velocity = -400
	velocity.y = jump_velocity


func jump_attack() -> void:
	is_invincible = true
	# Jumps.
	$AnimatedSprite2D.play("jump")
	jump_velocity = -800
	velocity.y = jump_velocity
	
	# Stops mid-air and hovers.
	await get_tree().create_timer(0.25).timeout
	is_hovering = true
	velocity.y = 0 # Stops velocity.
	
	# Chases target for a few seconds. Boss's move speed is increased.
	current_state = State.CHASE
	move_speed += 400
	await get_tree().create_timer(5).timeout
	
	# Still hovering, but stops moving horizontally for a moment.
	current_state = State.IDLE
	velocity.x = 0
	move_speed -= 400 # Movement speed is reduced.
	await get_tree().create_timer(1).timeout

	# Stops hovering and slams into floor.
	$AnimatedSprite2D.play("idle")
	is_hovering = false
	velocity.y += 800
	is_invincible = false
	
	# Stays on the ground for 3 seconds before moving again. If take_damage() activates, may enter chase earlier.
	await get_tree().create_timer(3).timeout
	$AnimatedSprite2D.play("moving")
	current_state = State.CHASE
	


func choose(array): # Not given a static type (Vector2) to ensure the function remains flexible for arrays too.
	array.shuffle()
	return array.front() # Chooses the first element in the array and returns it.


func face_target() -> void:
	# Gets the distance by taking the target's position vectors and subtracting the enemy's position vectors.
	var distance_to_target: Vector2 = target.global_position - global_position
	
	# Face left.
	if distance_to_target.x > 0:
		$AnimatedSprite2D.flip_h = true # Flips sprite horizontally.
		$MuzzleMarker.rotation_degrees = 180 # Rotates enemy muzzle to 180 degrees.
	# Face right.
	if distance_to_target.x < -0:
		$AnimatedSprite2D.flip_h = false
		$MuzzleMarker.rotation_degrees = 0 # Rotates enemy muzzle to 0 degrees.


# Faces enemy's sprite and gun depending on the direction it is in.
func face_direction() -> void:
	# Face left.
	if velocity.x > 0.707:
		$AnimatedSprite2D.flip_h = true # Flips sprite horizontally.
		$MuzzleMarker.rotation_degrees = 180 # Rotates enemy muzzle to 180 degrees.
	# Face right.
	if velocity.x < -0.707:
		$AnimatedSprite2D.flip_h = false
		$MuzzleMarker.rotation_degrees = 0 # Rotates enemy muzzle to 0 degrees.


func charging_shot() -> void:
	if not is_invincible:
		is_shooting = true
		is_invincible = true
		# TODO: Add lower-pitched charging sound.
		$AnimatedSprite2D.play("charge")
		$Sounds/Charging.play()
		print("Enemy is charging!")
		await get_tree().create_timer(3).timeout
		await shoot()
		is_shooting = false
		is_invincible = false


func shoot() -> void:
	await get_tree().create_timer(0.5).timeout # Windup before firing.
	create_bullet(3)
	await get_tree().create_timer(3).timeout # Cooldown after firing. Affects how long until enemy does next action.
	print("Boss has finished firing volley.")


func create_bullet(amount: int) -> void:
	for index in range(amount):
		await get_tree().create_timer(0.2).timeout # Cooldown.
		var b = bullet.instantiate()
		get_owner().call_deferred("add_child", b)
		b.transform = $MuzzleMarker.global_transform
		$AnimatedSprite2D.play("shoot")
		$Sounds/Shoot.play()


func take_damage(damage: float, _bullet_direction: String) -> void:
	# If the boss is invincible or inactive, exits out of function.
	if is_invincible or current_state == State.INACTIVE:
		return

	if taking_damage == false: # Prevents the enemy from taking too many instances of damage while the code runs.
		taking_damage = true
		health -= damage
		$Sounds/Hurt.play()
		print("Enemy current health: ", health)
		
		current_state = State.IDLE
		velocity.x = 0
		$AnimatedSprite2D.play("hurt")
		
		# Awaits the timeout of a timer of X seconds, created within the SceneTree, before continuing the code.
		await get_tree().create_timer(0.5).timeout
		
		# Removes the boss if it is dead, otherwise continues running code.
		if health <= 0:
			velocity = Vector2.ZERO
			current_state = State.INACTIVE
			$AnimatedSprite2D.visible = false
			$DeathAnimation.visible = true
			$DeathAnimation.play("death")
		else:
			$AnimatedSprite2D.play("moving")
			current_state = State.CHASE
			taking_damage = false


func _on_decision_timer_timeout() -> void:
	if current_state == State.CHASE and not is_invincible:
		var attack_choices: Array[String] = ["Jump Attack", "Charged Attack"]
		var choice: String = choose(attack_choices)
		match choice:
			"Jump Attack":
				jump_attack()
			"Charged Attack":
				current_state = State.SHOOT
	$DecisionTimer.wait_time = range(3, 6).pick_random()
	$DecisionTimer.start()


func _on_detection_area_body_entered(body: Node2D) -> void:
	# First time detection.
	if not target and body is Player: # If the enemy had no target:
		target = body # Sets Player as the target.
		$AnimatedSprite2D.play("moving")
		$DecisionTimer.wait_time = range(3, 6).pick_random()
		$DecisionTimer.start()
		print("DecisionTimer wait times set to: ", $DecisionTimer.get_wait_time())
			
		# TODO: If adding an intro, add code below here.
		current_state = State.CHASE


func _on_death_animation_animation_finished() -> void:
	SceneManager.boss_defeated = true
	print("Boss died. Something likely unlocked?")
	queue_free()
