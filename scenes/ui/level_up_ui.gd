extends CanvasLayer
## UI du jeu - HUD permanent + panneau de choix au level up.

const UPGRADES := [
	{"name": "Vitesse +15%", "key": "speed", "type": "multiply", "value": 1.15},
	{"name": "Cadence tir +20%", "key": "fire_rate", "type": "multiply", "value": 0.8},
	{"name": "Degats espresso +1", "key": "espresso_damage", "type": "add", "value": 1.0},
	{"name": "Portee espresso +25%", "key": "espresso_range", "type": "multiply", "value": 1.25},
	{"name": "Vitesse espresso +20%", "key": "espresso_speed", "type": "multiply", "value": 1.2},
]

var _player: CharacterBody2D
var _hud_label: Label
var _overlay: ColorRect
var _panel: VBoxContainer
var _choices: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	_build_level_up_panel()

	_player = get_parent().get_node("Player")
	_player.leveled_up.connect(_on_player_leveled_up)


func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		_hud_label.text = "Niv. %d  |  XP: %d / %d" % [
			_player.current_level, _player.current_xp, _player.xp_for_next_level
		]


func _build_hud() -> void:
	_hud_label = Label.new()
	_hud_label.position = Vector2(16, 8)
	_hud_label.add_theme_font_size_override("font_size", 22)
	add_child(_hud_label)


func _build_level_up_panel() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.visible = false
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_panel = VBoxContainer.new()
	_panel.custom_minimum_size = Vector2(320, 0)
	_panel.add_theme_constant_override("separation", 12)
	center.add_child(_panel)


func _on_player_leveled_up() -> void:
	_show_choices()


func _show_choices() -> void:
	# Nettoyer les anciens boutons
	for child in _panel.get_children():
		child.queue_free()

	# Titre
	var title := Label.new()
	title.text = "LEVEL UP !"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	_panel.add_child(title)

	# 3 améliorations aléatoires
	var pool := UPGRADES.duplicate()
	pool.shuffle()
	_choices = pool.slice(0, 3)

	for i in _choices.size():
		var btn := Button.new()
		btn.text = _choices[i].name
		btn.custom_minimum_size.y = 50
		btn.pressed.connect(_on_choice.bind(i))
		_panel.add_child(btn)

	_overlay.visible = true
	get_tree().paused = true


func _on_choice(index: int) -> void:
	var upgrade := _choices[index]
	_apply_upgrade(upgrade)
	_overlay.visible = false
	get_tree().paused = false


func _apply_upgrade(upgrade: Dictionary) -> void:
	var current_value: float = _player.get(upgrade.key)
	if upgrade.type == "multiply":
		_player.set(upgrade.key, current_value * upgrade.value)
	elif upgrade.type == "add":
		_player.set(upgrade.key, current_value + upgrade.value)

	# Si on change le fire_rate, mettre à jour le timer
	if upgrade.key == "fire_rate":
		_player.update_fire_timer()
