extends CharacterBody2D

# INFO: This script is for the player-controlled ship.
# TODO: Controls need to be adjusted to fit the intended asteroids feeling.

@export var speed = 400
@export var rotation_speed = 1.5

var rotation_direction = 0


func get_input():
	rotation_direction = Input.get_axis("left", "right")
	velocity = transform.x * Input.get_axis("down", "up") * speed

func _physics_process(delta):
	get_input()
	rotation += rotation_direction * rotation_speed * delta
	move_and_slide()
