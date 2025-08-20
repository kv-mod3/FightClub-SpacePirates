extends CharacterBody2D


enum State {
	IDLE,
	ROAM,
	JUMP,
	SHOOT
}

enum InitialDirection {Left, Right}
@export var initial_direction := InitialDirection.Left # Allows choosing initial direction within the editor.

@export var health: float = 25
@export var move_speed: float = 30
@export var acceleration: float = 5 # How quickly the node accelerates to target velocity.
@export var jump_velocity: float = -400

var bullet: PackedScene = preload("res://entities/enemies/PirateEnemy/pirate_bullet.tscn")

var current_state := State.ROAM
var shuffling_states: Array = [State.IDLE, State.ROAM]
var direction: Vector2
var instinct_to_jump: bool = false
var target: Node2D # Starts with a value of null on load. Currently unused.
var taking_damage: bool = false


func _ready() -> void:
	# Initial direction on scene load.
	match initial_direction:
		InitialDirection.Left:
			direction = Vector2.LEFT
			animate()
		InitialDirection.Right:
			direction = Vector2.RIGHT
			animate()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		match current_state:
			State.ROAM:
				move()
				if instinct_to_jump == false:
					instinct_to_jump = true # The instinctual need to jump becomes true.
					$JumpingTimer.start(range(5, 10).pick_random()) # Picks a time between 5-10 seconds, until jump.
			State.JUMP:
				jump()
				current_state = State.ROAM
			State.SHOOT:
				shoot()
	move_and_slide()


func animate() -> void:
	if direction == Vector2.RIGHT:
		$TestSprite2D.flip_h = true
		$DetectionArea2D/DetectCollisionShape.position = Vector2(108, -12) # Moves detection collision shape to the right.
		$MuzzleMarker.position = Vector2(20, 8) # Face enemy muzzle to the right.
		$MuzzleMarker.rotation_degrees = 180 # Sets the enemy muzzle to a rotation of 180 degrees.
	else:
		$TestSprite2D.flip_h = false
		$DetectionArea2D/DetectCollisionShape.position = Vector2(-108, -12) # Moves detection collision shape to the left.
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
	if current_state == State.ROAM:
		direction = choose([Vector2.LEFT, Vector2.RIGHT])
		animate()


func _on_jumping_timer_timeout() -> void:
	instinct_to_jump = false # Loses the instinct to jump.
	if current_state == State.ROAM: # Enemy only jumps if not roaming.
		current_state = State.JUMP


func shoot() -> void:
	var burst_fire: int = 0
	if burst_fire < 3:
		var b = bullet.instantiate()
		# owner.add_child(b) # Adds bullet to the root node of the scene the player is in, instead of to player themself.
		get_owner().call_deferred("add_child", b)
		b.transform = $MuzzleMarker.global_transform
		burst_fire += 1


func take_damage(damage) -> void:
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
	if body is Player:
		current_state = State.SHOOT # Enemy goes into SHOOT state.
		# target = body # Sets the enemy's target.
		print("Enemy detected Player.")


func _on_detection_area_2d_body_exited(body: Node2D) -> void:
	current_state = State.ROAM
	print("Enemy lost sight of Player.")
