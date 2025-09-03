extends CharacterBody2D

# NOTE: If you are reviewing this as a reference for movement, see the Boss's script. It is organized a bit better.

enum State {
	IDLE,
	MOVE,
	JUMP,
	SHOOT
}
enum InitialDirection {LEFT, RIGHT}
@export var initial_direction := InitialDirection.LEFT # Allows choosing initial direction within the editor.
enum EnemyMode {
	STATIONARY, ## Enemy stands still and shoots if player is detected.
	ROAMING ## Enemy moves back and forth, stops to shoot if player is detected, then resumes roaming.
}
@export var mode := EnemyMode.STATIONARY

var health: float = 25
var move_speed: float = 30
var acceleration: float = 5 # How quickly the node accelerates to target velocity.
var jump_velocity: float = -400
var bullet: PackedScene = preload("res://objects/enemies/PirateEnemy/pirate_bullet.tscn")

var current_state := State.MOVE
var direction: Vector2
var instinct_to_jump: bool = false
var target: Node2D # Starts with a value of null on load. Currently unused.
var is_shooting: bool = false
var taking_damage: bool = false
var is_dying: bool = false


func _ready() -> void:
	# Initial direction on scene load.
	match initial_direction:
		InitialDirection.LEFT:
			direction = Vector2.LEFT
			face_direction()
		InitialDirection.RIGHT:
			direction = Vector2.RIGHT
			face_direction()
	# Sets the starting state of the enemy depending on what behavior they are set to.
	match mode:
		EnemyMode.STATIONARY:
			current_state = State.IDLE
			$BlinkTimer.start(range(3, 6).pick_random())
		EnemyMode.ROAMING:
			current_state = State.MOVE


func _physics_process(delta: float) -> void:
	if is_dying:
		return
	# Player affected by gravity if not on floor.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		state_controller()
	move_and_slide()


func state_controller() -> void:
	match current_state:
		State.IDLE:
			if mode == EnemyMode.ROAMING: # Stops movement of enemies when entering IDLE.
				velocity = Vector2(0, 0) # BUG: Enemy falls down slower if caught in middle of jump.
			# If target exists AND enemy is not shooting AND is in within detection area, then shoot.
			if target and not is_shooting:
				shoot()
				print("Enemy sees you and shoots.")
		State.MOVE:
			move()
			if instinct_to_jump == false:
				instinct_to_jump = true # The instinctual need to jump becomes true.
				$JumpingTimer.start(range(5, 10).pick_random()) # Picks a time between 5-10 seconds, until jump.
		State.JUMP:
			jump()
			current_state = State.MOVE
		State.SHOOT:
			if not is_shooting:
				print("Enemy is firing!")
				await shoot()
				print("Finished shooting and moving to IDLE state.")
				current_state = State.IDLE


func move() -> void:
	# velocity = velocity.move_toward(direction * move_speed, acceleration)
	velocity = direction * move_speed
	if is_on_floor():
		$AnimatedSprite2D.play("walk")


func choose(array): # Not given a static type (Vector2) to ensure the function remains flexible for arrays too.
	array.shuffle()
	return array.front() # Chooses the first element in the array and returns it.


func _on_direction_timer_timeout() -> void:
	# If enemy is a roamer:
	if mode == EnemyMode.ROAMING:
		$DirectionTimer.wait_time = range(2, 5).pick_random()
		
		# Change direction only if moving.
		if current_state == State.MOVE:
			direction = choose([Vector2.LEFT, Vector2.RIGHT])
			face_direction()
		
		# If they were stopped and there is no target in sight, then move again.
		if current_state == State.IDLE and not target:
			current_state = State.MOVE


# Faces enemy's sprite and gun depending on the direction it is in.
func face_direction() -> void:
	# Face left.
	if direction.x > 0:
		$AnimatedSprite2D.flip_h = true # Flips sprite horizontally.
		$DetectionArea2D/DetectCollisionShape.position = Vector2(108, 0) # Moves detection collision shape.
		$MuzzleMarker.position = Vector2(19, 17) # Moves enemy muzzle.
		$MuzzleMarker.rotation_degrees = 180 # Rotates enemy muzzle to 180 degrees.
	# Face right.
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = false
		$DetectionArea2D/DetectCollisionShape.position = Vector2(-108, 0)
		$MuzzleMarker.position = Vector2(-19, 17)
		$MuzzleMarker.rotation_degrees = 0 # Rotates enemy muzzle to 0 degrees.


func jump() -> void:
	velocity.y = jump_velocity
	$Sounds/Jump.play()
	$AnimatedSprite2D.play("jump")


func _on_jumping_timer_timeout() -> void:
	instinct_to_jump = false # Loses the instinct to jump.
	if current_state == State.MOVE: # Enemy only jumps if not moving.
		current_state = State.JUMP


func shoot() -> void:
	is_shooting = true
	await get_tree().create_timer(0.5).timeout # Windup before firing.
	create_bullet()
	await get_tree().create_timer(3).timeout # Cooldown after firing. Affects how long until enemy does next action.
	is_shooting = false
	print("Enemy is ready to fire again.")


func create_bullet() -> void:
	var b = bullet.instantiate()
	get_owner().call_deferred("add_child", b)
	b.transform = $MuzzleMarker.global_transform
	$AnimatedSprite2D.play("shoot")
	$Sounds/Shoot.play()


func take_damage(damage: float, bullet_direction: String) -> void:
	# A reaction to surprise attacks.
	if not target:
		status_indicator("?!", "yellow")
	
	# Roaming enemies will stop.
	if mode == EnemyMode.ROAMING:
		current_state = State.IDLE
	
	# If ForgetTimer is still going, refresh the time.
	if not $ForgetTimer.is_stopped():
		$ForgetTimer.start()
		print("ForgetTimer has been refreshed.")
	
	if taking_damage == false: # Prevents the enemy from taking too many instances of damage while the code runs.
		taking_damage = true
		health -= damage
		$AnimatedSprite2D.play("hurt")
		$Sounds/Hurt.play()
		print("Enemy current health: ", health)
		
		# Plays animation if enemy is dead, otherwise continues running code.
		# NOTE: Enemy is freed from the scene once DeathAnimation finishes. See func further below.
		if health <= 0:
			is_dying = true
			$CollisionShape2D.set_deferred("disabled", true) # Disables collision shape.
			await get_tree().create_timer(0.5).timeout # Allows hurt animations to play out before death.
			$AnimatedSprite2D.visible = false
			$DeathAnimation.visible = true
			$DeathAnimation.play("death")
		else:
			await get_tree().create_timer(0.5).timeout
			$AnimatedSprite2D.play("idle") # Resets enemy sprite.
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


func _on_death_animation_animation_finished() -> void:
	print("Enemy died.")
	queue_free()


func _on_detection_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		if not target: # If the enemy had no target:
			target = body # Sets Player as the target.
			status_indicator("!", "red")
			$AnimatedSprite2D.play("attention")
			print("Enemy detected Player.")
			if mode == EnemyMode.ROAMING: # If enemy is roamer, stop movement immediately.
				current_state = State.IDLE
		# Checks if the enemy's forget timer has begun, if it has, stop the timer before it times out.
		if not $ForgetTimer.is_stopped():
			$ForgetTimer.stop()
			print("ForgetTimer was forcefully stopped.")


func _on_detection_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		target = null
		$ForgetTimer.start()
		print("Player has left the detection range. Enemy is beginning to forget.")


func _on_forget_timer_timeout() -> void:
	print("Enemy has forgotten and is now returning to its original behavior.")
	status_indicator("?", "white")
	# Roamers begin moving again.
	if mode == EnemyMode.ROAMING:
		current_state = State.MOVE
	if mode == EnemyMode.STATIONARY:
		$AnimatedSprite2D.play("idle")


func status_indicator(text: String, color: String) -> void:
	$StatusLabel.text = text
	if color == "red":
		$StatusLabel.label_settings.font_color = Color(1, 0, 0)
	if color == "yellow":
		$StatusLabel.label_settings.font_color = Color(0.95, 0.8, 0)
	if color == "white":
		$StatusLabel.label_settings.font_color = Color(1, 1, 1)
	$StatusLabel.visible = true
	await get_tree().create_timer(1).timeout
	$StatusLabel.visible = false


func _on_blink_timer_timeout() -> void:
	if $ForgetTimer.is_stopped():
		$AnimatedSprite2D.play("blink")
		await get_tree().create_timer(2).timeout
		$AnimatedSprite2D.play("idle")
		$BlinkTimer.start(range(4, 8).pick_random())
	else:
		$BlinkTimer.start(range(4, 8).pick_random())
