extends CharacterBody2D


enum State {
	IDLE,
	ROAM,
	JUMP,
	SHOOT
}

@export var health: float = 25
@export var move_speed: float = 30
@export var acceleration: float = 5 # How quickly the node accelerates to target velocity.
@export var jump_velocity: float = -400

var current_state := State.ROAM
var shuffling_states: Array = [State.IDLE, State.ROAM]
var direction: Vector2
var instinct_rising: bool = false

var dealing_damage: bool = false
var taking_damage: bool = false


func _ready() -> void:	
	pass


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		match current_state:
			State.ROAM:
				move()
				if instinct_rising == false:
					instinct_rising = true # The instinctual need to jump becomes true.
					$JumpingTimer.start(range(5, 10).pick_random()) # Picks a time between 5-10 seconds, until jump.
			State.JUMP:
				jump()
				current_state = State.ROAM
				if instinct_rising == true:
					instinct_rising = false
	move_and_slide()


func animate() -> void:
	if direction == Vector2.RIGHT:
		$TestSprite2D.flip_h = true
	else:
		$TestSprite2D.flip_h = false


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
	current_state = State.JUMP


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
	
		# Enemy returns to original color.
		var original_color: Color = Color(1, 1, 1)
		modulate = original_color
		
		taking_damage = false
