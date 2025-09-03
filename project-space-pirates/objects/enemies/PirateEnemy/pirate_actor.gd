extends CharacterBody2D

enum State {
	MOVE,
	JUMP,
}
enum InitialDirection {LEFT, RIGHT}
@export var initial_direction := InitialDirection.LEFT # Allows choosing initial direction within the editor.

@export var move_speed: float = 250
var acceleration: float = 5 # How quickly the node accelerates to target velocity.
var jump_velocity: float = -400

var current_state := State.MOVE
var direction: Vector2
var instinct_to_jump: bool = false
@export var is_frozen: bool = true


func _ready() -> void:
	# Initial direction on scene load.
	match initial_direction:
		InitialDirection.LEFT:
			direction = Vector2.LEFT
			face_direction()
		InitialDirection.RIGHT:
			direction = Vector2.RIGHT
			face_direction()
	# Begin jumping timer.
	$JumpingTimer.start(range(3, 5).pick_random())
	$AnimatedSprite2D.modulate = Color(0.5, 0.5, 0.5)


func _physics_process(delta: float) -> void:
	if SceneManager.escape_seq_active:
		is_frozen = false
	
	if is_frozen:
		return
	# Player affected by gravity if not on floor.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		state_controller()
	move_and_slide()


func state_controller() -> void:
	match current_state:
		State.MOVE:
			move()
			if not instinct_to_jump:
				instinct_to_jump = true # The instinctual need to jump becomes true.
		State.JUMP:
			jump()
			current_state = State.MOVE


func move() -> void:
	# velocity = velocity.move_toward(direction * move_speed, acceleration)
	velocity = direction * move_speed
	if is_on_floor():
		$AnimatedSprite2D.play("walk")


# Faces enemy's sprite and gun depending on the direction it is in.
func face_direction() -> void:
	# Face right.
	if direction.x > 0:
		$AnimatedSprite2D.flip_h = true # Flips sprite horizontally.
	# Face left.
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = false


func jump() -> void:
	velocity.y = jump_velocity
	$Sounds/Jump.play()
	$AnimatedSprite2D.play("jump")


func _on_jumping_timer_timeout() -> void:
	if instinct_to_jump and current_state == State.MOVE and not is_frozen:
		instinct_to_jump = false # Loses the instinct to jump.
		$JumpingTimer.start(range(3, 5).pick_random())
		current_state = State.JUMP
	else:
		$JumpingTimer.start(range(3, 5).pick_random())


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
