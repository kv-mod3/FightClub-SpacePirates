extends CharacterBody2D


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
var shuffling_states: Array = [State.IDLE, State.MOVE]
var direction: Vector2
var instinct_to_jump: bool = false
var target: Node2D # Starts with a value of null on load. Currently unused.
var is_shooting: bool = false
var taking_damage: bool = false


func _ready() -> void:
	# Initial direction on scene load.
	match initial_direction:
		InitialDirection.LEFT:
			direction = Vector2.LEFT
			face_direction()
		InitialDirection.RIGHT:
			direction = Vector2.RIGHT
			face_direction()
	# Sets whether the enemy is stationary or roaming.
	match mode:
		EnemyMode.STATIONARY:
			current_state = State.IDLE
		EnemyMode.ROAMING:
			current_state = State.MOVE


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
			if target and not is_shooting:
				# TODO: Fix the overlapping method to only include the Player.
				# Currently it detects if ANY body is overlapping the enemy's detection radius.
				if $DetectionArea2D.has_overlapping_bodies():
					shoot()
					print("Enemy sees you and shoots.")
				else:
					direction = (target.global_position - global_position).normalized()
					face_direction()
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

# Faces enemy depending on which direction it is looking at.
func face_direction() -> void:
	if direction.x > 0:
		$TestSprite2D.flip_h = true
		$DetectionArea2D/DetectCollisionShape.position = Vector2(108, 0) # Moves detection collision shape to the right.
		$MuzzleMarker.position = Vector2(20, 8) # Face enemy muzzle to the right.
		$MuzzleMarker.rotation_degrees = 180 # Sets the enemy muzzle to a rotation of 180 degrees.
	if direction.x < 0:
		$TestSprite2D.flip_h = false
		$DetectionArea2D/DetectCollisionShape.position = Vector2(-108, 0) # Moves detection collision shape to the left.
		$MuzzleMarker.position = Vector2(-20, 8) # Face enemy muzzle to the left.
		$MuzzleMarker.rotation_degrees = 0 # Sets the enemy muzzle to a rotation of 180 degrees.


func move() -> void:
	# velocity = velocity.move_toward(direction * move_speed, acceleration)
	velocity = direction * move_speed


func jump() -> void:
	velocity.y = jump_velocity


func choose(array): # Not given a static type (Vector2) to ensure the function remains flexible for arrays too.
	array.shuffle()
	return array.front() # Chooses the first element in the array and returns it.


func _on_direction_timer_timeout() -> void:
	$DirectionTimer.wait_time = range(2, 5).pick_random()
	if current_state == State.MOVE:
		direction = choose([Vector2.LEFT, Vector2.RIGHT])
		face_direction()


func _on_jumping_timer_timeout() -> void:
	instinct_to_jump = false # Loses the instinct to jump.
	if current_state == State.MOVE: # Enemy only jumps if not moving.
		current_state = State.JUMP


func shoot() -> void:
	is_shooting = true
	await create_bullet(3)
	print("Enemy's gun is on cooldown.")
	await get_tree().create_timer(3).timeout # Cooldown after firing. Affects how long until enemy does next action.
	is_shooting = false
	print("Enemy is ready to fire again.")


func create_bullet(amount: int) -> void:
	for index in range(amount):
		await get_tree().create_timer(0.2).timeout # Cooldown before the next bullet fired.
		var b = bullet.instantiate()
		get_owner().call_deferred("add_child", b)
		b.transform = $MuzzleMarker.global_transform


func take_damage(damage: float) -> void:
	# TODO: Have enemy move forward if shot.
	if not target:
		# target = 
		print("Your bullet hit the enemy before he could see you.")
	if taking_damage == false: # Prevents the enemy from taking too many instances of damage while the code runs.
		taking_damage = true
		health -= damage
		print("Enemy current health: ", health)
	
		# Enemy flashes red on hit.
		var flash_red_color: Color = Color(50, 0.5, 0.5)
		modulate = flash_red_color
	
		# Awaits the timeout of a timer of 0.2 seconds, created within the SceneTree, before continuing the code.
		await get_tree().create_timer(0.2).timeout
		
		# Removes the enemy if it is dead, otherwise continues running code.
		if health <= 0:
			queue_free()
			print("Enemy died.")
	
		# Enemy returns to original color.
		var original_color: Color = Color(1, 1, 1)
		modulate = original_color
		
		taking_damage = false


func _on_detection_area_2d_body_entered(body: Node2D) -> void:
	# TODO: Check the following "if" statement to see if it even makes sense.
	if body is Player and not target: # If Player detected, and the enemy had no target:
		print("Enemy detected Player.")
		target = body # Sets Player as the target.
		if mode == EnemyMode.ROAMING: # If enemy is roamer, stop movement immediately. BUG: Enemy falls down slower if caught in middle of jump.
			velocity = Vector2(0, 0)
		await status_indicator("!", Color(1, 0, 0))
		current_state = State.IDLE


func _on_detection_area_2d_body_exited(body: Node2D) -> void:
# TODO: Check if there's anything that could be done for stationary enemies.
	if body is Player:
		print("Player has left the detection range, but the enemy is aware that they are still there.")
		await status_indicator("?", Color(0.95, 0.8, 0))
		# BUG: Currently broken, needs to be after the enemy loses sight of player.
		if mode == EnemyMode.ROAMING: # NOTE: Bug may be related to targeting note clearing instead, actually.
			$DirectionTimer.wait_time = 5
			current_state = State.MOVE


func status_indicator(text: String, color: Color) -> void:
	$StatusLabel.text = text
	$StatusLabel.label_settings.font_color = color
	$StatusLabel.visible = true
	await get_tree().create_timer(1).timeout
	$StatusLabel.visible = false
