extends Node
## Autoload - sauvegarde persistante des pourboires et bonus permanents.

const SAVE_PATH := "user://save_game.cfg"

# Monnaie persistante
var tips: int = 0

# Barista selectionne pour la prochaine partie
var selected_barista: Resource = null

# Bonus permanents (achetables en magasin)
var perm_speed_mult: float = 1.0
var perm_max_hp_add: float = 0.0
var perm_damage_mult: float = 1.0
var perm_magnet_add: float = 0.0


func _ready() -> void:
	load_data()


func add_tips(amount: int) -> void:
	tips += amount
	save_data()


func spend_tips(amount: int) -> bool:
	if tips < amount:
		return false
	tips -= amount
	save_data()
	return true


func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("currency", "tips", tips)
	config.set_value("bonuses", "speed_mult", perm_speed_mult)
	config.set_value("bonuses", "max_hp_add", perm_max_hp_add)
	config.set_value("bonuses", "damage_mult", perm_damage_mult)
	config.set_value("bonuses", "magnet_add", perm_magnet_add)
	config.save(SAVE_PATH)


func load_data() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		# Premier lancement, pas de fichier — on garde les valeurs par defaut
		return
	tips = config.get_value("currency", "tips", 0)
	perm_speed_mult = config.get_value("bonuses", "speed_mult", 1.0)
	perm_max_hp_add = config.get_value("bonuses", "max_hp_add", 0.0)
	perm_damage_mult = config.get_value("bonuses", "damage_mult", 1.0)
	perm_magnet_add = config.get_value("bonuses", "magnet_add", 0.0)


func reset_data() -> void:
	tips = 0
	perm_speed_mult = 1.0
	perm_max_hp_add = 0.0
	perm_damage_mult = 1.0
	perm_magnet_add = 0.0
	save_data()
