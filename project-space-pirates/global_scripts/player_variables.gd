extends Node

# Minimum and maximum health values, used to clamp health.
const MIN_HEALTH: float = 0.0
const MAX_HEALTH: float = 100.0

var health: float = 100:
	set(new_value):
		health = clampf(new_value, MIN_HEALTH, MAX_HEALTH) # Clamps the health between the set range.

var ammo: int = 6
var is_reloading: bool = false
var reloading_progress: float = 0
