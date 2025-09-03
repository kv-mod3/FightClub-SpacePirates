extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ShipDoorClose.play()

func _process(delta: float) -> void:
	if SceneManager.boss_defeated:
		$Level1BGM.stop()
		await get_tree().create_timer(0.2).timeout
		
		# Changes screens
		$Screens/TL/ScreenTL.color = Color(1, 0, 0) # To red
		$Screens/TM/ScreenTM.color = Color(1, 0, 0)
		$Screens/TR/ScreenTR.color = Color(1, 0, 0)
		$Screens/BL/ScreenBL.color = Color(1, 0, 0)
		$Screens/BL/Label1.visible = true
		$Screens/BR/ScreenBR.color = Color(1, 0, 0)
		$Screens/BR/Label2.visible = true
		$Screens/Red/ScreenRed.color = Color(0, 0, 0) # To black
		$Screens/Dim/ScreenDim.color = Color(0, 0, 0)
