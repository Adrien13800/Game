extends Area2D
## Flaque de lait d'avoine - ralentit les ennemis dans la zone.

var slow_factor: float = 0.4
var duration: float = 3.5
var radius: float = 60.0
var dps: float = 0.5
var _timer: float = 0.0
var _dps_tick: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_timer = duration

	var shape := CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape

	$Visual.offset_left = -radius
	$Visual.offset_top = -radius
	$Visual.offset_right = radius
	$Visual.offset_bottom = radius

	$Visual.visible = false
	var spr := Sprite2D.new()
	spr.texture = preload("res://assets/sprites/oat_milk_puddle.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite_scale := radius / 32.0
	spr.scale = Vector2(sprite_scale, sprite_scale)
	add_child(spr)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_timer -= delta
	modulate.a = min(1.0, _timer / 0.5)
	if _timer <= 0.0:
		for body in get_overlapping_bodies():
			if body.has_method("remove_slow"):
				body.remove_slow()
		queue_free()
		return

	# DPS aux ennemis dans la zone
	_dps_tick += delta
	if _dps_tick >= 0.5:
		_dps_tick = 0.0
		for body in get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(dps)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("apply_slow"):
		body.apply_slow()


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("remove_slow"):
		body.remove_slow()
