extends CanvasLayer
## Écran titre - menu principal de Caffeine Crisis.

const SHOP_ITEMS := [
	{"label": "Vitesse +5%", "field": "perm_speed_mult", "add": 0.05, "cost": 5},
	{"label": "HP Max +3", "field": "perm_max_hp_add", "add": 3.0, "cost": 8},
	{"label": "Degats +10%", "field": "perm_damage_mult", "add": 0.10, "cost": 10},
	{"label": "Aimant XP +20", "field": "perm_magnet_add", "add": 20.0, "cost": 6},
]

const BARISTAS := [
	preload("res://resources/baristas/apprenti.tres"),
	preload("res://resources/baristas/senior.tres"),
	preload("res://resources/baristas/cappuccino.tres"),
]

var _main_panel: VBoxContainer
var _shop_panel: VBoxContainer
var _select_panel: VBoxContainer
var _bg: ColorRect
var _center: CenterContainer
var _tips_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	get_tree().paused = true


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.1, 0.07, 0.05, 1)
	add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_center = CenterContainer.new()
	_bg.add_child(_center)
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_main_menu()
	_build_shop()
	_build_select()
	_shop_panel.visible = false
	_select_panel.visible = false


func _build_main_menu() -> void:
	_main_panel = VBoxContainer.new()
	_main_panel.custom_minimum_size = Vector2(400, 0)
	_main_panel.add_theme_constant_override("separation", 20)
	_main_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.add_child(_main_panel)

	var title := Label.new()
	title.text = "CAFFEINE CRISIS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2, 1))
	_main_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Un lundi matin parmi tant d'autres..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4, 1))
	_main_panel.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	_main_panel.add_child(spacer)

	var play_btn := Button.new()
	play_btn.text = "JOUER"
	play_btn.custom_minimum_size.y = 60
	play_btn.add_theme_font_size_override("font_size", 24)
	play_btn.pressed.connect(_open_select)
	_main_panel.add_child(play_btn)

	var shop_btn := Button.new()
	shop_btn.text = "MAGASIN"
	shop_btn.custom_minimum_size.y = 50
	shop_btn.add_theme_font_size_override("font_size", 20)
	shop_btn.pressed.connect(_open_shop)
	_main_panel.add_child(shop_btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size.y = 20
	_main_panel.add_child(spacer2)

	var controls := Label.new()
	controls.text = "WASD / Fleches  -  Deplacer\nTir automatique  -  Esquive et survie !"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color(0.5, 0.4, 0.35, 1))
	_main_panel.add_child(controls)

	var credits := Label.new()
	credits.text = "v0.1  -  Fait avec Godot 4"
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.add_theme_font_size_override("font_size", 12)
	credits.add_theme_color_override("font_color", Color(0.35, 0.3, 0.25, 1))
	_main_panel.add_child(credits)


func _build_shop() -> void:
	_shop_panel = VBoxContainer.new()
	_shop_panel.custom_minimum_size = Vector2(450, 0)
	_shop_panel.add_theme_constant_override("separation", 14)
	_shop_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.add_child(_shop_panel)

	var shop_title := Label.new()
	shop_title.text = "MAGASIN"
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title.add_theme_font_size_override("font_size", 36)
	shop_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3, 1))
	_shop_panel.add_child(shop_title)

	_tips_label = Label.new()
	_tips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tips_label.add_theme_font_size_override("font_size", 20)
	_tips_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2, 1))
	_shop_panel.add_child(_tips_label)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	_shop_panel.add_child(spacer)

	for i in SHOP_ITEMS.size():
		var item = SHOP_ITEMS[i]
		var btn := Button.new()
		btn.custom_minimum_size.y = 45
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_buy.bind(i, btn))
		_update_shop_btn(btn, item)
		_shop_panel.add_child(btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size.y = 10
	_shop_panel.add_child(spacer2)

	var back_btn := Button.new()
	back_btn.text = "RETOUR"
	back_btn.custom_minimum_size.y = 50
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(_close_shop)
	_shop_panel.add_child(back_btn)


func _update_shop_btn(btn: Button, item: Dictionary) -> void:
	var current: float = GlobalStats.get(item.field)
	var display: String
	if item.field.ends_with("_mult"):
		display = "%d%%" % int((current - 1.0) * 100)
	else:
		display = "%d" % int(current)
	btn.text = "%s  (actuel: %s)  -  %d Tips" % [item.label, display, item.cost]


func _open_shop() -> void:
	_main_panel.visible = false
	_shop_panel.visible = true
	_refresh_shop()


func _close_shop() -> void:
	_shop_panel.visible = false
	_main_panel.visible = true


func _refresh_shop() -> void:
	_tips_label.text = "Pourboires : %d" % GlobalStats.tips
	var btn_index := 0
	for child in _shop_panel.get_children():
		if child is Button and child.text != "RETOUR":
			_update_shop_btn(child, SHOP_ITEMS[btn_index])
			btn_index += 1


func _on_buy(index: int, btn: Button) -> void:
	var item = SHOP_ITEMS[index]
	if GlobalStats.spend_tips(item.cost):
		var current: float = GlobalStats.get(item.field)
		GlobalStats.set(item.field, current + item.add)
		GlobalStats.save_data()
		_refresh_shop()


func _build_select() -> void:
	_select_panel = VBoxContainer.new()
	_select_panel.custom_minimum_size = Vector2(500, 0)
	_select_panel.add_theme_constant_override("separation", 16)
	_select_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.add_child(_select_panel)

	var select_title := Label.new()
	select_title.text = "CHOISIS TON BARISTA"
	select_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_title.add_theme_font_size_override("font_size", 32)
	select_title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2, 1))
	_select_panel.add_child(select_title)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	_select_panel.add_child(spacer)

	for i in BARISTAS.size():
		var barista = BARISTAS[i]
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		_select_panel.add_child(hbox)

		# Apercu couleur du personnage
		var preview := ColorRect.new()
		preview.custom_minimum_size = Vector2(40, 50)
		preview.color = barista.color
		hbox.add_child(preview)

		# Info + bouton
		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_box.add_theme_constant_override("separation", 4)
		hbox.add_child(info_box)

		var name_label := Label.new()
		name_label.text = barista.display_name
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", barista.color)
		info_box.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = barista.description
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 1))
		info_box.add_child(desc_label)

		var stats_label := Label.new()
		stats_label.text = "VIT: %d  |  PV: %d  |  ATK: %.1f  |  Cadence: %.2fs" % [
			int(barista.base_speed), int(barista.base_max_hp),
			barista.base_espresso_damage, barista.base_fire_rate
		]
		stats_label.add_theme_font_size_override("font_size", 12)
		stats_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4, 1))
		info_box.add_child(stats_label)

		var pick_btn := Button.new()
		pick_btn.text = "CHOISIR"
		pick_btn.custom_minimum_size = Vector2(100, 50)
		pick_btn.add_theme_font_size_override("font_size", 16)
		pick_btn.pressed.connect(_on_pick_barista.bind(i))
		hbox.add_child(pick_btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size.y = 10
	_select_panel.add_child(spacer2)

	var back_btn := Button.new()
	back_btn.text = "RETOUR"
	back_btn.custom_minimum_size.y = 45
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_close_select)
	_select_panel.add_child(back_btn)


func _open_select() -> void:
	_main_panel.visible = false
	_select_panel.visible = true


func _close_select() -> void:
	_select_panel.visible = false
	_main_panel.visible = true


func _on_pick_barista(index: int) -> void:
	GlobalStats.selected_barista = BARISTAS[index]
	var player = get_parent().get_node("Player")
	player.apply_barista(BARISTAS[index])
	get_tree().paused = false
	queue_free()
