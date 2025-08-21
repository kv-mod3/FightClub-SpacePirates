class_name Player
extends CharacterBody2D

# INFO: This is the player with platformer controls.

@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
var bullet: PackedScene = preload("res://objects/player/PlayerPlatformer/player_bullet.tscn")

var test_var: bool = false


func _ready() -> void:
	# Grabs the health in player_variables and replaces the placeholder in string (and formats it into an floored int).
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	
	# Alternative with same result:
	# $CanvasLayer/HealthLabel.text = "HP: " + str(int(PlayerVariables.health))
	return
	print("I still printed despite the return.")


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

	face_direction()
	move_and_slide()


# Animate Player
func face_direction() -> void:
	if velocity.x < 0:
		$TestSprite2D.flip_h = true
		$MuzzleMarker.position = Vector2(-18, 2) # Face player muzzle to the left.
		$MuzzleMarker.rotation_degrees = 180 # Sets the player muzzle to a rotation of 180 degrees.
	if velocity.x > 0:
		$TestSprite2D.flip_h = false
		$MuzzleMarker.position = Vector2(18, 2) # Face player muzzle to the right (default).
		$MuzzleMarker.rotation_degrees = 0 # Sets the player muzzle back to its original rotation.


func shoot() -> void:
	if $ShootCooldownTimer.is_stopped():
		$ShootCooldownTimer.start()
		var b = bullet.instantiate()
		owner.add_child(b) # Adds bullet to the root node of the scene the player is in, instead of to player themself.
		b.transform = $MuzzleMarker.global_transform


func take_damage(damage: float) -> void:
	# TODO: Add sound effects.
	PlayerVariables.health -= damage
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	print("Player took %d damage!" % damage)
	print("Current Player HP: ", PlayerVariables.health)


func restore_health(health) -> void:
	# TODO: Add sound effects.
	PlayerVariables.health += health
	$CanvasLayer/HealthLabel.text = "HP: %d" % PlayerVariables.health
	print("Player HP restored by %d" % health)
	print("Current Player HP: ", PlayerVariables.health)
