extends "res://scenes/enemies/zombie_client.gd"
## Boss zombie - gros, lent, charge periodiquement vers le joueur.

signal boss_defeated

var _charge_timer: Timer
var _is_charging := false
var _charge_speed: float = 350.0
var _charge_duration: float = 0.8
var _charge_elapsed: float = 0.0
var max_hp: float


func _ready() -> void:
	super._ready()
	max_hp = hp

	_charge_timer = Timer.new()
	_charge_timer.wait_time = 4.0
	_charge_timer.autostart = true
	add_child(_charge_timer)
	_charge_timer.timeout.connect(_start_charge)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	if _is_charging:
		_charge_elapsed += delta
		if _charge_elapsed >= _charge_duration:
			_is_charging = false
			modulate = Color(1, 1, 1, 1)
		else:
			move_and_slide()
			_animate_enemy_sprite(delta, 0.08)
			return

	var direction := global_position.direction_to(_target.global_position)
	var current_speed := speed * (0.4 if _slow_stacks > 0 else 1.0)
	velocity = direction * current_speed
	move_and_slide()
	_animate_enemy_sprite(delta, 0.15)


func _animate_enemy_sprite(delta: float, interval: float) -> void:
	if not _enemy_sprite:
		return
	if velocity.x != 0:
		_enemy_sprite.flip_h = velocity.x < 0
	if velocity.length_squared() > 1.0:
		_anim_timer += delta
		if _anim_timer >= interval:
			_anim_timer -= interval
			_enemy_sprite.frame = (_enemy_sprite.frame + 1) % 4
	else:
		_enemy_sprite.frame = 0
		_anim_timer = 0.0


func _start_charge() -> void:
	if not is_instance_valid(_target):
		return
	_is_charging = true
	_charge_elapsed = 0.0
	var dir := global_position.direction_to(_target.global_position)
	velocity = dir * _charge_speed
	modulate = Color(1.5, 0.3, 0.3, 1)


func take_damage(amount: float) -> void:
	hp -= amount
	if is_instance_valid(_target):
		_target.add_damage(amount)
	if hp <= 0:
		if is_instance_valid(_target):
			_target.add_kill()
		boss_defeated.emit()
		_death_effect()
		_drop_xp()
		_maybe_drop_tip()
		queue_free()
	else:
		_hit_flash()


func _setup_sprite() -> void:
	_enemy_sprite = Sprite2D.new()
	_enemy_sprite.texture = preload("res://assets/sprites/zombie_boss.png")
	_enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_enemy_sprite.hframes = 4
	_enemy_sprite.scale = Vector2(2, 2)
	add_child(_enemy_sprite)
