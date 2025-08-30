extends CharacterBody2D

enum State {
	IDLE,
	CHASE,
	JUMP,
	SHOOT
}

var health: float = 100
var move_speed: float = 30
var acceleration: float = 5 # How quickly the node accelerates to target velocity.
var jump_velocity: float = -400
var bullet: PackedScene = preload("res://objects/enemies/PirateEnemy/pirate_bullet.tscn")

var current_state := State.IDLE
var shuffling_states: Array = [State.IDLE, State.CHASE]
var direction: Vector2
var instinct_to_jump: bool = false
var target: Node2D # Starts with a value of null on load. Currently unused.
var is_shooting: bool = false
var taking_damage: bool = false


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	# Player affected by gravity if not on floor.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		state_controller()
	move_and_slide()


func state_controller() -> void:
	match current_state:
		State.IDLE:
			# If target exists AND enemy is not shooting AND is in within detection area, then shoot.
			if target and not is_shooting:
				# if $DetectionArea2D.has_overlapping_bodies(): # TODO: Change the overlapping method to only include the Player.
				shoot()
				print("Enemy sees you and shoots.")
		State.CHASE:
			chase_target()
			face_direction()
		State.JUMP:
			jump()
		State.SHOOT:
			if not is_shooting:
				print("Enemy is firing!")
				await shoot()
				print("Finished shooting and moving to IDLE state.")
				current_state = State.IDLE


func move() -> void:
	# velocity = velocity.move_toward(direction * move_speed, acceleration)
	velocity = direction * move_speed


func choose(array): # Not given a static type (Vector2) to ensure the function remains flexible for arrays too.
	array.shuffle()
	return array.front() # Chooses the first element in the array and returns it.


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


func jump() -> void:
	velocity.y = jump_velocity


func chase_target():
	if target: # Executes if target contains a value, otherwise fails.
		var distance_to_player: Vector2
		
		# Gets the distance by taking the target's position vectors and subtracting the enemy's position vectors.
		distance_to_player = target.global_position - global_position
		
		# Normalizes the vector so that only the direction to the target remains.
		var direction_normal: Vector2 = distance_to_player.normalized()
		
		# Takes the velocity and moves it towards a target velocity in small increments.
		velocity = velocity.move_toward(direction_normal * move_speed, acceleration)


func shoot() -> void:
	is_shooting = true
	await get_tree().create_timer(0.5).timeout # Windup before firing.
	create_bullet(3)
	# $Shoot.play
	await get_tree().create_timer(3).timeout # Cooldown after firing. Affects how long until enemy does next action.
	is_shooting = false
	print("Boss is ready to fire again.")


func create_bullet(amount: int) -> void:
	for index in range(amount):
		await get_tree().create_timer(0.2).timeout # Cooldown.
		var b = bullet.instantiate()
		get_owner().call_deferred("add_child", b)
		b.transform = $MuzzleMarker.global_transform


func take_damage(damage: float, bullet_direction: String) -> void:
	# A reaction to surprise attacks.
	if not target:
		pass
	
	# If ForgetTimer is still going, refresh the time.
	if not $ForgetTimer.is_stopped():
		$ForgetTimer.start()
		print("ForgetTimer has been refreshed.")
	
	if taking_damage == false: # Prevents the enemy from taking too many instances of damage while the code runs.
		taking_damage = true
		health -= damage
		print("Enemy current health: ", health)
		
		# Enemy flashes red on hit.
		var flash_red_color: Color = Color(50, 0.5, 0.5)
		modulate = flash_red_color
		
		# Awaits the timeout of a timer of 0.2 seconds, created within the SceneTree, before continuing the code.
		await get_tree().create_timer(0.2).timeout
		
		# Removes the boss if it is dead, otherwise continues running code.
		if health <= 0:
			queue_free()
			SceneManager.boss_defeated = true
			print("Boss died. Something likely unlocked?")
		
		# Enemy returns to original color.
		var original_color: Color = Color(1, 1, 1)
		modulate = original_color
		
		taking_damage = false
		
	# NOTE: The following code is here at the bottom to give the enemy a moment to understand it got hurt.
	# TODO: Might want to move it into the nested block above though.
	# Faces enemy towards the direction of the Player's bullets, but only if the enemy was facing away from bullet direction.
	if bullet_direction == "left" and direction.x < 0:
		direction = Vector2.RIGHT
		face_direction()
	if bullet_direction == "right" and direction.x > 0:
		direction = Vector2.LEFT
		face_direction()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player:
		if not target: # If the enemy had no target:
			target = body # Sets Player as the target.
			$AnimatedSprite2D.play("walk")
			current_state = State.CHASE
