extends StaticBody2D

var is_opening: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_opening == true:
		pass

# Opens door upon being hit by Player bullet.
func open() -> void:
	pass
