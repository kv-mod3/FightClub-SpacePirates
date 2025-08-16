class_name Player
extends CharacterBody2D

# INFO: This is the player with platformer controls.
# TODO: Fix the bullets in bullet script not shooting left.

@export var move_speed = 200.0
@export var jump_velocity = -400.0
@export var bullet := preload("res://entities/player/PlayerBullet/player_bullet.tscn")
var facing_left: bool = false

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
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed) # moves toward a destination speed before stopping.

	face_player()
	move_and_slide()


# Animate Player
func face_player() -> void:
	if velocity.x < 0:
		$TestSprite2D.flip_h = true
		$Muzzle.position = Vector2(-13, 2) # Face muzzle to the left.
	if velocity.x > 0:
		$TestSprite2D.flip_h = false
		$Muzzle.position = Vector2(13, 2) # Face muzzle to the right.


func shoot() -> void:
	var b = bullet.instantiate()
	owner.add_child(b) # Adds bullet to the root node of the scene the player is in, instead of to player themself.
	b.transform = $Muzzle.global_transform
