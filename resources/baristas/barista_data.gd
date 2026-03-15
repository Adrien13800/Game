extends Resource
class_name BaristaData
## Profil d'un barista jouable.

@export var display_name: String = "Barista"
@export var description: String = ""
@export var color: Color = Color(0.55, 0.35, 0.17, 1)
@export var sprite_path: String = ""

# Stats de base
@export var base_speed: float = 300.0
@export var base_max_hp: float = 10.0
@export var base_fire_rate: float = 0.4
@export var base_espresso_damage: float = 1.0
@export var base_espresso_speed: float = 500.0
@export var base_espresso_range: float = 600.0

# Arme de depart
@export var start_with_oat_milk: bool = false
@export var start_with_shuriken: bool = false
