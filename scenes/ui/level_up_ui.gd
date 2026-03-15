extends CanvasLayer
## UI du jeu - HUD, barre de vie, level up, game over.

const UPGRADES := [
	{"name": "Vitesse +15%", "key": "speed", "type": "multiply", "value": 1.15},
	{"name": "Cadence tir +20%", "key": "fire_rate", "type": "multiply", "value": 0.8},
	{"name": "Degats espresso +1", "key": "espresso_damage", "type": "add", "value": 1.0},
	{"name": "Portee espresso +25%", "key": "espresso_range", "type": "multiply", "value": 1.25},
	{"name": "Vitesse espresso +20%", "key": "espresso_speed", "type": "multiply", "value": 1.2},
	{"name": "HP Max +3", "key": "max_hp", "type": "add", "value": 3.0},
	{"name": "Lait d'avoine (ralentit)", "key": "oat_milk", "type": "weapon"},
	{"name": "Touillette +1 (orbite)", "key": "shurikens", "type": "weapon"},
	{"name": "Soin +4 HP", "key": "heal", "type": "action", "value": 4.0},
	{"name": "Aimant XP +50%", "key": "xp_magnet_range", "type": "multiply", "value": 1.5},
	{"name": "Bouclier +2 charges", "key": "shield", "type": "action", "value": 2},
	{"name": "Multi-shot +1", "key": "espresso_count", "type": "add", "value": 1.0},
	{"name": "Pierce +1 (traverse)", "key": "espresso_pierce", "type": "add", "value": 1.0},
	{"name": "DPS flaque +0.5", "key": "oat_milk_dps", "type": "action", "value": 0.5},
	{"name": "Touillette degats +1", "key": "shuriken_damage", "type": "add", "value": 1.0},
]

var _player: CharacterBody2D
var _hud_label: Label
var _hp_bar_bg: ColorRect
var _hp_bar: ColorRect
var _shield_label: Label
var _boss_bar_bg: ColorRect
var _boss_bar: ColorRect
var _boss_label: Label
var _time_elapsed: float = 0.0
var _spawner: Node

# Level up
var _overlay: ColorRect
var _panel: VBoxContainer
var _choices: Array = []

# Game over
var _go_overlay: ColorRect
var _go_panel: VBoxContainer
var _upgrades_chosen: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	_build_level_up_panel()
	_build_game_over_panel()

	_player = get_parent().get_node("Player")
	_player.leveled_up.connect(_on_player_leveled_up)
	_player.died.connect(_on_player_died)
	_player.hit_taken.connect(_on_player_hit)
	_player.shield_hit.connect(_on_shield_hit)
	_spawner = get_parent().get_node("EnemySpawner")


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	if not _player._is_dead and not get_tree().paused:
		_time_elapsed += delta

	var time_str := "%d:%02d" % [int(_time_elapsed) / 60, int(_time_elapsed) % 60]
	_hud_label.text = "Niv. %d  |  XP: %d / %d  |  Tips: %d  |  %s" % [
		_player.current_level, _player.current_xp, _player.xp_for_next_level,
		GlobalStats.tips, time_str
	]

	var hp_ratio: float = _player.current_hp / _player.max_hp
	_hp_bar.size.x = 200.0 * hp_ratio
	if hp_ratio > 0.5:
		_hp_bar.color = Color(0.2, 0.8, 0.2, 1)
	elif hp_ratio > 0.25:
		_hp_bar.color = Color(0.9, 0.7, 0.1, 1)
	else:
		_hp_bar.color = Color(0.9, 0.2, 0.1, 1)

	if _player.shield_charges > 0:
		_shield_label.text = "BOUCLIER x%d" % _player.shield_charges
		_shield_label.visible = true
	else:
		_shield_label.visible = false

	# Barre de vie du boss
	if is_instance_valid(_spawner) and is_instance_valid(_spawner.current_boss):
		var boss = _spawner.current_boss
		var boss_ratio: float = boss.hp / boss.max_hp
		_boss_bar.size.x = 600.0 * boss_ratio
		_boss_label.visible = true
		_boss_bar_bg.visible = true
		_boss_bar.visible = true
	else:
		_boss_label.visible = false
		_boss_bar_bg.visible = false
		_boss_bar.visible = false


# --- HUD ---

func _build_hud() -> void:
	_hud_label = Label.new()
	_hud_label.position = Vector2(16, 8)
	_hud_label.add_theme_font_size_override("font_size", 22)
	add_child(_hud_label)

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.position = Vector2(16, 40)
	_hp_bar_bg.size = Vector2(200, 14)
	_hp_bar_bg.color = Color(0.3, 0.1, 0.1, 1)
	add_child(_hp_bar_bg)

	_hp_bar = ColorRect.new()
	_hp_bar.position = Vector2(16, 40)
	_hp_bar.size = Vector2(200, 14)
	_hp_bar.color = Color(0.2, 0.8, 0.2, 1)
	add_child(_hp_bar)

	_shield_label = Label.new()
	_shield_label.position = Vector2(224, 36)
	_shield_label.add_theme_font_size_override("font_size", 18)
	_shield_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 1))
	_shield_label.visible = false
	add_child(_shield_label)

	# Barre de vie du boss (en bas, centree)
	_boss_label = Label.new()
	_boss_label.position = Vector2(440, 660)
	_boss_label.add_theme_font_size_override("font_size", 20)
	_boss_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8, 1))
	_boss_label.text = "BOSS"
	_boss_label.visible = false
	add_child(_boss_label)

	_boss_bar_bg = ColorRect.new()
	_boss_bar_bg.position = Vector2(340, 688)
	_boss_bar_bg.size = Vector2(600, 16)
	_boss_bar_bg.color = Color(0.2, 0.05, 0.15, 1)
	_boss_bar_bg.visible = false
	add_child(_boss_bar_bg)

	_boss_bar = ColorRect.new()
	_boss_bar.position = Vector2(340, 688)
	_boss_bar.size = Vector2(600, 16)
	_boss_bar.color = Color(0.7, 0.1, 0.5, 1)
	_boss_bar.visible = false
	add_child(_boss_bar)


# --- Coffee Splash ---

func _on_player_hit() -> void:
	_spawn_coffee_splash()


func _spawn_coffee_splash() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var splash_count := randi_range(3, 6)

	for i in splash_count:
		var splat := ColorRect.new()
		var size_x := randf_range(30, 80)
		var size_y := randf_range(20, 60)
		splat.size = Vector2(size_x, size_y)
		splat.position = Vector2(
			randf_range(0, viewport_size.x - size_x),
			randf_range(0, viewport_size.y - size_y)
		)
		# Teintes café variées
		var brown := randf_range(0.25, 0.45)
		splat.color = Color(brown + 0.15, brown, brown * 0.4, randf_range(0.4, 0.7))
		splat.rotation = randf_range(-0.5, 0.5)
		splat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(splat)

		# Fade out
		var tween := create_tween()
		tween.tween_interval(randf_range(0.1, 0.3))
		tween.tween_property(splat, "modulate:a", 0.0, randf_range(0.5, 1.0))
		tween.tween_callback(splat.queue_free)

	# Vignette rouge-brun sur tout l'écran
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.35, 0.15, 0.05, 0.3)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var v_tween := create_tween()
	v_tween.tween_property(vignette, "modulate:a", 0.0, 0.4)
	v_tween.tween_callback(vignette.queue_free)


# --- Shield Hit ---

func _on_shield_hit() -> void:
	_spawn_shield_flash()


func _spawn_shield_flash() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	# Bordure bleue sur tout l'écran (effet bouclier)
	var border := ColorRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.color = Color(0.2, 0.5, 1.0, 0.4)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	var b_tween := create_tween()
	b_tween.tween_property(border, "modulate:a", 0.0, 0.3)
	b_tween.tween_callback(border.queue_free)

	# Eclats de bouclier (fragments bleus)
	var shard_count := randi_range(4, 8)
	for i in shard_count:
		var shard := ColorRect.new()
		var size_val := randf_range(8, 20)
		shard.size = Vector2(size_val, size_val)
		shard.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)
		shard.color = Color(
			randf_range(0.3, 0.5),
			randf_range(0.6, 0.9),
			1.0,
			randf_range(0.5, 0.8)
		)
		shard.rotation = randf_range(0, TAU)
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shard)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(shard, "modulate:a", 0.0, randf_range(0.3, 0.6))
		tween.tween_property(shard, "scale", Vector2(2.5, 2.5), 0.4)
		tween.chain().tween_callback(shard.queue_free)


# --- Level Up ---

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
	for child in _panel.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "LEVEL UP !"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	_panel.add_child(title)

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
	var upgrade = _choices[index]
	_upgrades_chosen.append(upgrade.name)
	_apply_upgrade(upgrade)
	_overlay.visible = false
	get_tree().paused = false


func _apply_upgrade(upgrade: Dictionary) -> void:
	if upgrade.type == "weapon":
		if upgrade.key == "oat_milk":
			_player.unlock_oat_milk()
		elif upgrade.key == "shurikens":
			_player.unlock_shurikens()
		return

	if upgrade.type == "action":
		if upgrade.key == "heal":
			_player.heal(upgrade.value)
		elif upgrade.key == "shield":
			_player.shield_charges += int(upgrade.value)
		elif upgrade.key == "oat_milk_dps":
			_player.oat_milk_dps += upgrade.value
		return

	var current_value: float = _player.get(upgrade.key)
	if upgrade.type == "multiply":
		_player.set(upgrade.key, current_value * upgrade.value)
	elif upgrade.type == "add":
		_player.set(upgrade.key, current_value + upgrade.value)

	if upgrade.key == "fire_rate":
		_player.update_fire_timer()
	if upgrade.key == "max_hp":
		_player.current_hp += upgrade.value
	if upgrade.key == "shuriken_damage" and _player.shuriken_count > 0:
		_player._respawn_all_shurikens()


# --- Game Over ---

func _build_game_over_panel() -> void:
	_go_overlay = ColorRect.new()
	_go_overlay.color = Color(0.15, 0, 0, 0.75)
	_go_overlay.visible = false
	add_child(_go_overlay)
	_go_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_go_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_go_panel = VBoxContainer.new()
	_go_panel.custom_minimum_size = Vector2(320, 0)
	_go_panel.add_theme_constant_override("separation", 16)
	center.add_child(_go_panel)


func _on_player_died() -> void:
	_show_game_over()


func _show_game_over() -> void:
	for child in _go_panel.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	_go_panel.add_child(title)

	var time_str := "%d:%02d" % [int(_time_elapsed) / 60, int(_time_elapsed) % 60]

	var stats_text := "Niveau %d  |  Temps : %s\n" % [_player.current_level, time_str]
	stats_text += "Kills : %d\n" % _player.total_kills
	stats_text += "Degats infliges : %d\n" % int(_player.total_damage_dealt)

	if _upgrades_chosen.size() > 0:
		stats_text += "\nUpgrades :\n"
		for u in _upgrades_chosen:
			stats_text += "  - %s\n" % u

	var stats := Label.new()
	stats.text = stats_text
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 18)
	_go_panel.add_child(stats)

	var btn := Button.new()
	btn.text = "Recommencer"
	btn.custom_minimum_size.y = 50
	btn.pressed.connect(_restart)
	_go_panel.add_child(btn)

	var menu_btn := Button.new()
	menu_btn.text = "Menu Principal"
	menu_btn.custom_minimum_size.y = 50
	menu_btn.pressed.connect(_go_to_menu)
	_go_panel.add_child(menu_btn)

	_go_overlay.visible = true
	get_tree().paused = true


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
