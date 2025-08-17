extends Node

# Minmium and maximum health allowed.
const MIN_HEALTH: float = 0.0
const MAX_HEALTH: float = 100.0

var health: float = 100:
	set(new_value):
		health = clamp(new_value, MIN_HEALTH, MAX_HEALTH) # Clamps the health between the set range.
