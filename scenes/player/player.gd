extends CharacterBody2D
## Barista - déplacement, tir auto, XP, level up, HP, armes.

signal leveled_up
signal died
signal hit_taken
signal shield_hit

const EspressoScene := preload("res://scenes/weapons/espresso_shot.tscn")
const OatMilkScene := preload("res://scenes/weapons/oat_milk_puddle.tscn")
const ShurikenScene := preload("res://scenes/weapons/stirrer_shuriken.tscn")

@export var speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1800.0
@export var fire_rate: float = 0.4
@export var espresso_damage: float = 1.0
@export var espresso_range: float = 600.0
@export var espresso_speed: float = 500.0
@export var max_hp: float = 10.0
@export var iframe_duration: float = 0.5

var facing_direction := Vector2.RIGHT
var current_xp: int = 0
var current_level: int = 1
var xp_for_next_level: int = 5
var current_hp: float
var _fire_timer: Timer
var _iframe_timer: float = 0.0
var _hurtbox: Area2D
var _is_dead := false
var _sprite: Sprite2D
var _anim_timer: float = 0.0

# Lait d'avoine
var _oat_milk_active := false
var _oat_milk_timer: Timer
var oat_milk_interval: float = 4.0
var oat_milk_duration: float = 3.5
var oat_milk_radius: float = 60.0
var oat_milk_dps: float = 0.5

# Touillettes
var shuriken_count: int = 0
var shuriken_damage: float = 3.0

# Aimant XP
var xp_magnet_range: float = 100.0

# Bouclier
var shield_charges: int = 0

# Multi-shot
var espresso_count: int = 1

# Pierce
var espresso_pierce: int = 1

# Stats
var total_kills: int = 0
var total_damage_dealt: float = 0.0


func _ready() -> void:
	# Si on revient d'un game over, le barista est deja choisi
	if GlobalStats.selected_barista:
		_apply_barista_stats(GlobalStats.selected_barista)

	# Appliquer les bonus permanents du magasin
	speed *= GlobalStats.perm_speed_mult
	max_hp += GlobalStats.perm_max_hp_add
	espresso_damage *= GlobalStats.perm_damage_mult
	xp_magnet_range += GlobalStats.perm_magnet_add

	current_hp = max_hp
	$Visual.visible = false
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.hframes = 4
	add_child(_sprite)
	_setup_hurtbox()
	_fire_timer = Timer.new()
	_fire_timer.wait_time = fire_rate
	_fire_timer.autostart = true
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_shoot)

	if GlobalStats.selected_barista:
		if GlobalStats.selected_barista.start_with_oat_milk:
			call_deferred("unlock_oat_milk")
		if GlobalStats.selected_barista.start_with_shuriken:
			call_deferred("unlock_shurikens")


func apply_barista(barista: Resource) -> void:
	_apply_barista_stats(barista)
	speed *= GlobalStats.perm_speed_mult
	max_hp += GlobalStats.perm_max_hp_add
	espresso_damage *= GlobalStats.perm_damage_mult
	xp_magnet_range += GlobalStats.perm_magnet_add
	current_hp = max_hp
	_fire_timer.wait_time = fire_rate
	if barista.start_with_oat_milk:
		call_deferred("unlock_oat_milk")
	if barista.start_with_shuriken:
		call_deferred("unlock_shurikens")


func _apply_barista_stats(barista: Resource) -> void:
	speed = barista.base_speed
	max_hp = barista.base_max_hp
	fire_rate = barista.base_fire_rate
	espresso_damage = barista.base_espresso_damage
	espresso_speed = barista.base_espresso_speed
	espresso_range = barista.base_espresso_range
	$Visual.color = barista.color
	if barista.sprite_path != "" and _sprite:
		_sprite.texture = load(barista.sprite_path)
		_sprite.hframes = 4
		_sprite.scale = Vector2(2, 2)


func _setup_hurtbox() -> void:
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = 2
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	_hurtbox.add_child(col)
	add_child(_hurtbox)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	var direction := _get_input_direction()

	if direction != Vector2.ZERO:
		facing_direction = direction
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
		if _sprite:
			if direction.x != 0:
				_sprite.flip_h = direction.x < 0
			_anim_timer += delta
			if _anim_timer >= 0.15:
				_anim_timer -= 0.15
				_sprite.frame = (_sprite.frame + 1) % 4
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if _sprite:
			_sprite.frame = 0
			_anim_timer = 0.0

	move_and_slide()

	if _iframe_timer > 0.0:
		_iframe_timer -= delta
		modulate.a = 0.3 if fmod(_iframe_timer * 8.0, 1.0) > 0.5 else 1.0
	else:
		modulate.a = 1.0
		_check_enemy_contact()


func _check_enemy_contact() -> void:
	for body in _hurtbox.get_overlapping_bodies():
		if body.has_method("get_damage"):
			_take_hit(body.get_damage())
			return


func _take_hit(dmg: float) -> void:
	if shield_charges > 0:
		shield_charges -= 1
		_iframe_timer = iframe_duration
		_shield_break_effect()
		shield_hit.emit()
		return
	current_hp -= dmg
	_iframe_timer = iframe_duration
	_screen_shake(5.0, 0.15)
	hit_taken.emit()
	if current_hp <= 0.0:
		current_hp = 0.0
		_is_dead = true
		_fire_timer.stop()
		died.emit()


func _shield_break_effect() -> void:
	modulate = Color(0.3, 0.6, 1.0, 1)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25)


func _screen_shake(intensity: float, duration: float) -> void:
	var cam := $Camera2D
	var tween := create_tween()
	tween.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity, 0.03)
	tween.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity * 0.5, 0.03)
	tween.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity * 0.2, 0.03)
	tween.tween_property(cam, "offset", Vector2.ZERO, 0.06)


func _get_nearest_enemies_on_screen(count: int) -> Array:
	var half_screen := get_viewport_rect().size / 2.0
	var candidates: Array = []

	for enemy in get_tree().get_nodes_in_group("enemies"):
		var diff: Vector2 = enemy.global_position - global_position
		if abs(diff.x) > half_screen.x or abs(diff.y) > half_screen.y:
			continue
		candidates.append({"enemy": enemy, "dist": diff.length_squared()})

	candidates.sort_custom(func(a, b): return a.dist < b.dist)

	var result: Array = []
	for i in mini(count, candidates.size()):
		result.append(candidates[i].enemy)
	return result


func _shoot() -> void:
	if _is_dead:
		return
	var targets := _get_nearest_enemies_on_screen(espresso_count)

	if targets.size() == 0:
		_spawn_shot(facing_direction)
		return

	for i in espresso_count:
		var t = targets[i % targets.size()]
		var dir := global_position.direction_to(t.global_position)
		_spawn_shot(dir)


func _spawn_shot(dir: Vector2) -> void:
	var shot := EspressoScene.instantiate()
	shot.direction = dir
	shot.global_position = global_position
	shot.damage = espresso_damage
	shot.max_range = espresso_range
	shot.speed = espresso_speed
	shot.pierce = espresso_pierce
	get_parent().add_child(shot)


func collect_xp(amount: int) -> void:
	current_xp += amount
	if current_xp >= xp_for_next_level:
		current_xp -= xp_for_next_level
		current_level += 1
		xp_for_next_level = int(xp_for_next_level * 1.4)
		leveled_up.emit()


func update_fire_timer() -> void:
	_fire_timer.wait_time = fire_rate


func heal(amount: float) -> void:
	current_hp = minf(current_hp + amount, max_hp)


func get_magnet_range() -> float:
	return xp_magnet_range


func add_kill() -> void:
	total_kills += 1


func add_damage(amount: float) -> void:
	total_damage_dealt += amount


# --- Armes supplémentaires ---

func unlock_oat_milk() -> void:
	if not _oat_milk_active:
		_oat_milk_active = true
		_oat_milk_timer = Timer.new()
		_oat_milk_timer.wait_time = oat_milk_interval
		_oat_milk_timer.autostart = true
		add_child(_oat_milk_timer)
		_oat_milk_timer.timeout.connect(_spawn_puddle)
	else:
		oat_milk_radius += 15.0
		oat_milk_duration += 0.5


func _spawn_puddle() -> void:
	if _is_dead:
		return
	var puddle := OatMilkScene.instantiate()
	puddle.global_position = global_position
	puddle.slow_factor = 0.4
	puddle.duration = oat_milk_duration
	puddle.radius = oat_milk_radius
	puddle.dps = oat_milk_dps
	get_parent().call_deferred("add_child", puddle)


func unlock_shurikens() -> void:
	shuriken_count += 1
	_respawn_all_shurikens()


func _respawn_all_shurikens() -> void:
	for child in get_parent().get_children():
		if child.has_method("is_shuriken"):
			child.queue_free()
	for i in shuriken_count:
		var s := ShurikenScene.instantiate()
		s.initialize(self, (TAU / shuriken_count) * i)
		s.damage = shuriken_damage
		get_parent().call_deferred("add_child", s)


func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0

	return dir.normalized()
