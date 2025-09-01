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
var shuffling_states: Array = [State.IDLE, State.CHASE]
var direction: Vector2
var target: Node2D # Starts with a value of null on load. Currently unused.
var is_shooting: bool = false
var taking_damage: bool = false
var is_invincible: bool = true # Is invincible at the start to prevent cheese.


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
		State.INACTIVE:
			pass
		State.IDLE:
			pass
		State.CHASE:
			chase_target()
			face_direction()
		State.JUMP:
			jump()
			# TODO: Add exiting state here.
		State.SHOOT:
			face_target()
			if not is_shooting:
				charging_shot()


func move() -> void:
	# velocity = velocity.move_toward(direction * move_speed, acceleration)
	velocity = direction * move_speed


func jump() -> void:
	jump_velocity = -400
	velocity.y = jump_velocity


func choose(array): # Not given a static type (Vector2) to ensure the function remains flexible for arrays too.
	array.shuffle()
	return array.front() # Chooses the first element in the array and returns it.


func face_target() -> void:
	var distance_to_target: Vector2
	
	# Gets the distance by taking the target's position vectors and subtracting the enemy's position vectors.
	distance_to_target = target.global_position - global_position
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


func chase_target():
	var distance_to_player: Vector2
	
	# Gets the distance by taking the target's position vectors and subtracting the enemy's position vectors.
	distance_to_player = target.global_position - global_position
	
	# INFO: Minimum distance until boss enters shoot state.
	if distance_to_player.x >= -96 and distance_to_player.x <= 96:
		velocity = Vector2.ZERO
		current_state = State.SHOOT
		return
	
	# Normalizes the vector so that only the direction to the target remains.
	var direction_normal: Vector2 = distance_to_player.normalized()
	
	# Takes the velocity and moves it towards a target velocity in small increments.
	velocity = velocity.move_toward(direction_normal * move_speed, acceleration)


func charging_shot() -> void:
	if not is_invincible:
		is_shooting = true
		is_invincible = true
		# TODO: Add lower-pitched charging sound.
		$AnimatedSprite2D.play("charge")
		print("Enemy is charging!")
		await get_tree().create_timer(3).timeout
		$AnimatedSprite2D.play("shoot")
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
		$Sounds/Shoot.play()


func take_damage(damage: float, bullet_direction: String) -> void:
	# If the boss is invincible, exits out of function.
	if is_invincible:
		pass

	if taking_damage == false: # Prevents the enemy from taking too many instances of damage while the code runs.
		taking_damage = true
		health -= damage
		$Sounds/Hurt.play()
		print("Enemy current health: ", health)
		
		# Enemy flashes red on hit.
		var flash_red_color: Color = Color(50, 0.5, 0.5)
		modulate = flash_red_color
		
		# Awaits the timeout of a timer of 0.2 seconds, created within the SceneTree, before continuing the code.
		await get_tree().create_timer(0.2).timeout
		
		# Removes the boss if it is dead, otherwise continues running code.
		if health <= 0:
			velocity = Vector2.ZERO
			$AnimatedSprite2D.visible = false
			$DeathAnimation.visible = true
			$DeathAnimation.play("death")
		
		# Enemy returns to original color.
		var original_color: Color = Color(1, 1, 1)
		modulate = original_color
		
		taking_damage = false


func _on_detection_area_body_entered(body: Node2D) -> void:
	if not target and body is Player: # If the enemy had no target:
		target = body # Sets Player as the target.
		$AnimatedSprite2D.play("walk")
			
		# TODO: If adding an intro, replace these lines.
		is_invincible = false
		current_state = State.CHASE


func _on_death_animation_animation_finished() -> void:
	SceneManager.boss_defeated = true
	print("Boss died. Something likely unlocked?")
	queue_free()
