extends Area2D
## Touillette shuriken - orbite autour du barista et blesse les ennemis.

var orbit_speed: float = 5.0
var orbit_radius: float = 100.0
var damage: float = 3.0
var _angle: float = 0.0
var _player: Node2D
var _hit_cooldowns: Dictionary = {}
var _hit_cooldown_time: float = 0.5


func initialize(player: Node2D, start_angle: float) -> void:
	_player = player
	_angle = start_angle


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	$Visual.visible = false
	var spr := Sprite2D.new()
	spr.texture = preload("res://assets/sprites/stirrer_shuriken.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.hframes = 4
	spr.scale = Vector2(1.5, 1.5)
	add_child(spr)
	var anim_tween := create_tween().set_loops()
	for i in 4:
		anim_tween.tween_callback(spr.set.bind("frame", i))
		anim_tween.tween_interval(0.08)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		queue_free()
		return
	_angle += orbit_speed * delta
	global_position = _player.global_position + Vector2(cos(_angle), sin(_angle)) * orbit_radius

	# Tick cooldowns et re-check les overlaps
	var to_remove: Array = []
	for enemy_id in _hit_cooldowns:
		_hit_cooldowns[enemy_id] -= delta
		if _hit_cooldowns[enemy_id] <= 0.0:
			to_remove.append(enemy_id)
	for enemy_id in to_remove:
		_hit_cooldowns.erase(enemy_id)

	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			var id := body.get_instance_id()
			if not _hit_cooldowns.has(id):
				body.take_damage(damage)
				_hit_cooldowns[id] = _hit_cooldown_time


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var id := body.get_instance_id()
		if not _hit_cooldowns.has(id):
			body.take_damage(damage)
			_hit_cooldowns[id] = _hit_cooldown_time


func is_shuriken() -> bool:
	return true
