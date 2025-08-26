extends Area2D


@export var checkpoint_name: String
var is_activated: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not is_activated:
		is_activated = true
		SceneManager.current_checkpoint = checkpoint_name
		print("Saved at a checkpoint.")


func _on_player_platformer_died() -> void:
	# NOTE: Works, but is NOT an efficient method because the "died" signal is sent out to ALL checkpoints in scene.
	if SceneManager.current_checkpoint == checkpoint_name:
		# TODO: Needs some way to grab the Player body.
		# Player.global_position = self.global_position
		
		# Resets health and ammo.
		PlayerVariables.health = 100
		PlayerVariables.ammo = 3
