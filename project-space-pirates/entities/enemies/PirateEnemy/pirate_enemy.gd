extends CharacterBody2D


enum State {
	IDLE,
	SHOOT,
	ROAM,
	JUMP,
	DEATH
}

@export var health: int = 20
@export var move_speed: float = 30
@export var acceleration: float = 5 # How quickly the node accelerates to target velocity.
@export var jump_velocity: float = -400

var current_state = State.ROAM
var shuffling_states: Array = [State.IDLE, State.ROAM]
var direction: Vector2
var will_stop: bool = false
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


func move_enemy():
	# velocity = velocity.move_toward(direction * move_speed, acceleration)
	velocity = direction * move_speed


func jump() -> void:
	velocity.y = jump_velocity


func choose(array):
	array.shuffle()
	return array.front() # Chooses the first element in the array and returns it.


func _on_direction_timer_timeout() -> void:
	$DirectionTimer.wait_time = range(2, 5).pick_random()
	if current_state == State.ROAM:
		direction = choose([Vector2.LEFT, Vector2.RIGHT])


func _on_jumping_timer_timeout() -> void:
	current_state = State.JUMP
