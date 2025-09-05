extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ShipDoorClose.play()
	SceneManager.asteria_core_position = $AsteriaCore.global_position
	print("core position: ", SceneManager.asteria_core_position)

func _process(delta: float) -> void:
	if SceneManager.boss_battle_begin:
		$Level1BGM.stop()
		$InvisiWall/CollisionShape2D.set_deferred("disabled", false)
	if SceneManager.escape_seq_active:
		# Disables collision for the exit
		$InvisiWallRight/CollisionShape2D.set_deferred("disabled", true)
		
		# Changes screens
		$Screens/TL/ScreenTL.color = Color(1, 0, 0) # To red
		$Screens/TM/ScreenTM.color = Color(1, 0, 0)
		$Screens/TM/Label3.visible = true
		$Screens/TR/ScreenTR.color = Color(1, 0, 0)
		$Screens/BL/ScreenBL.color = Color(1, 0, 0)
		$Screens/BL/Label1.visible = true
		$Screens/BR/ScreenBR.color = Color(1, 0, 0)
		$Screens/BR/Label2.visible = true
		$Screens/Red/ScreenRed.color = Color(0, 0, 0) # To black
		$Screens/Dim/ScreenDim.color = Color(0, 0, 0)
		$BigContainer/Glass2.color = Color(1, 0.412, 0.18, 0.353)
		
		# Flood it with red.
		$CoreRoomBG.color = Color(0.9, 0.18, 0.18)
		$"SpaceShip/Boss Area/Boss Floor".color = Color(0.59, 0.147, 0.147)
		$"SpaceShip/Bridge Collision/Bridge".color = Color(0.59, 0.147, 0.147)
		$"SpaceShip/Macguffin Room/Treasure Room".color = Color(0.59, 0.147, 0.147)
		$"SpaceShip/Space Ship Corridor Polys/SpaceShip Corridor".color = Color(0.59, 0.147, 0.147)
		$Objects/Container.modulate = Color(0.59, 0.147, 0.147)
		$Objects/Container2.modulate = Color(0.59, 0.147, 0.147)
		$Objects/Container3.modulate = Color(0.59, 0.147, 0.147)
		$Objects/Container4.modulate = Color(0.59, 0.147, 0.147)
		$Objects/Container5.modulate = Color(0.59, 0.147, 0.147)
		$BigContainer/TopPoly1.modulate = Color(0.59, 0.147, 0.147)
		$BigContainer/TopPoly2.modulate = Color(0.59, 0.147, 0.147)
		$BigContainer/TopPoly4.modulate = Color(0.59, 0.147, 0.147)
		$BigContainer/TopPoly5.modulate = Color(0.59, 0.147, 0.147)
		$BigContainer/TopPoly6.modulate = Color(0.59, 0.147, 0.147)
		$BigContainer/BotPoly4.modulate = Color(0.59, 0.147, 0.147)
		$BigContainer/BotPoly5.modulate = Color(0.59, 0.147, 0.147)
		$AsteriaCore/AnimationPlayer.play("unstable")
		$Actors.visible = true
