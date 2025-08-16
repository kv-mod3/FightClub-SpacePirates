extends CharacterBody2D

enum State {
	IDLE,
	NEW_DIRECTION,
	MOVE
}

var current_state = State.IDLE
var shuffle_ready_states: Array # An array that is a copy of enum State that is ready to be shuffled.
var direction: Vector2 = Vector2.DOWN
var will_stop: bool = false

@export var move_speed: float = 30
@export var acceleration: float = 5 # How quickly the node accelerates to target velocity.

@export var dialogue_lines: Array[String] = ["Hello there!", "Today is a good day.", "Cya later."]
var dialogue_index: int = 0 # Used as an index for the "dialogue_lines" array.
var can_interact: bool = false


func _ready() -> void:	
	for element in State: # For each element in State:
		shuffle_ready_states.push_back(State[element]) # Appends to the end of array.
	$Timer.start(range(1, 5).pick_random()) # Starts the timer with a randomized wait time (integers) in seconds.


func _physics_process(delta: float) -> void:
	interact_dialogue()
	match current_state:
		State.IDLE:
			pass
		State.NEW_DIRECTION:
			direction = choose([Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT])
			face_direction()
			current_state = State.IDLE
		State.MOVE:
			move_forward()
			move_and_slide()
			
			if not will_stop: # Prevents code from running too many times.
				will_stop = true
				$Timer.paused = true
				
				# Creates temporary timer (in seconds) that the NPC is allowed to move before stopping.
				await get_tree().create_timer(1).timeout # Pauses the code until timeout, then continues.
				stop_move()
				current_state = State.IDLE
				$Timer.paused = false
				will_stop = false


func face_direction() -> void:
	match direction:
		Vector2.UP:
			$AnimatedSprite2D.play("idle_up")
		Vector2.DOWN:
			$AnimatedSprite2D.play("idle_down")
		Vector2.LEFT:
			$AnimatedSprite2D.play("idle_left")
		Vector2.RIGHT:
			$AnimatedSprite2D.play("idle_right")


func move_forward() -> void:
	velocity = velocity.move_toward(direction * move_speed, acceleration)
	
	match direction:
		Vector2.UP:
			$AnimatedSprite2D.play("move_up")
		Vector2.DOWN:
			$AnimatedSprite2D.play("move_down")
		Vector2.LEFT:
			$AnimatedSprite2D.play("move_left")
		Vector2.RIGHT:
			$AnimatedSprite2D.play("move_right")


func stop_move() -> void:
	velocity = Vector2(0, 0) # Resets velocity. Stops movement if currently moving.
	face_direction() # Set to idle animation.
	print("stop_move() finished execution.")


func choose(array):
	var process_array: Array = array
	process_array.shuffle()
	return process_array.front() # Chooses the first element in the array and returns it.


func _on_timer_timeout() -> void:
	if current_state == State.MOVE: # A failsafe in case there are wait time differences between timers.
		stop_move()
	$Timer.wait_time = range(2, 5).pick_random()
	current_state = choose(shuffle_ready_states)
	
	# For debugging
	match current_state:
		0:
			print("CHOSEN --> IDLE STATE")
		1:
			print("CHOSEN --> NEW_DIRECTION STATE")
		2:
			print("Chosen --> MOVE STATE")


func interact_dialogue() -> void:
	# Chat with NPC.
	if Input.is_action_just_pressed("interact") and can_interact:
		# Prevents the index from going out of bounds.
		if dialogue_index < dialogue_lines.size():
			$DialogueLayer.visible = true # Enables the dialogue layer.
			get_tree().paused = true # Pauses game.
				
			# Changes the text within DialogueLabel.
			$DialogueLayer/DialogueLabel.text = dialogue_lines[dialogue_index]
			dialogue_index += 1 # Increments the index.
		else:
			$DialogueLayer.visible = false
			get_tree().paused = false
			dialogue_index = 0 # Resets the index.
