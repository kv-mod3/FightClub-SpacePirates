class_name Player
extends CharacterBody2D

# INFO: This is the player with platformer controls.

@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var bullet: PackedScene = preload("res://entities/player/PlayerPlatformer/player_bullet.tscn")


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	if Input.is_action_just_pressed("shoot"):
		shoot()

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed) # Moves toward a destination speed before stopping.

	face_player()
	move_and_slide()


# Animate Player
func face_player() -> void:
	if velocity.x < 0:
		$TestSprite2D.flip_h = true
		$Muzzle.position = Vector2(-18, 2) # Face muzzle to the left.
		$Muzzle.rotation_degrees = 180 # Sets the muzzle to a rotation of 180 degrees.
	if velocity.x > 0:
		$TestSprite2D.flip_h = false
		$Muzzle.position = Vector2(18, 2) # Face muzzle to the right (default).
		$Muzzle.rotation_degrees = 0 # Sets the muzzle back to its original rotation.


func shoot() -> void:
	if $ShootCooldownTimer.is_stopped():
		$ShootCooldownTimer.start()
		var b = bullet.instantiate()
		owner.add_child(b) # Adds bullet to the root node of the scene the player is in, instead of to player themself.
		b.transform = $Muzzle.global_transform


func _on_shoot_cooldown_timer_timeout() -> void:
	print("Ready to shoot.")
