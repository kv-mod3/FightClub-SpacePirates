extends CharacterBody2D

var is_opening: bool = false
var is_opened: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_opening == true:
		pass

# Opens door upon being hit by Player bullet.
func open() -> void:
	$Polygon2D/SensorLeft.color = Color(0.26, 1, 0.26)
	$Polygon2D/SensorRight.color = Color(0.26, 1, 0.26)
