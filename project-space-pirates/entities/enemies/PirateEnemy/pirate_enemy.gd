class_name Enemy
extends CharacterBody2D


enum State {
	IDLE,
	SHOOT,
	ROAM,
	JUMP,
	DEATH
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
				move_enemy()
				animate_enemy()
				if instinct_rising == false:
					instinct_rising = true
					$JumpingTimer.start(range(5, 10).pick_random())
			State.JUMP:
				jump()
				current_state = State.ROAM
				if instinct_rising == true:
					instinct_rising = false
	move_and_slide()


func animate_enemy() -> void:
	if direction == Vector2.RIGHT:
		$TestSprite2D.flip_h = true
	else:
		$TestSprite2D.flip_h = false


func move_enemy() -> void:
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


func _on_jumping_timer_timeout() -> void:
	current_state = State.JUMP


func take_damage(damage) -> void:
	# TODO: Prevent enemy taking damage multiple times while animating.
	health -= damage
	print("Enemy current health: ", health)
	
	# Enemy flashes red on hit.
	var flash_red_color: Color = Color(50, 0.5, 0.5)
	modulate = flash_red_color
	
	if health <= 0:
		queue_free()
		# TODO: Add dying state.
	
	# Awaits the timeout of a timer of 0.2 seconds, created within the SceneTree, before continuing down the code.
	await get_tree().create_timer(0.2).timeout
	
	# Enemy returns to original color.
	var original_color: Color = Color(1, 1, 1)
	modulate = original_color
