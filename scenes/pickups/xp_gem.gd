extends Area2D
## Gemme d'XP - attirée par le joueur, collectée au contact.

@export var xp_value: int = 1
@export var magnet_speed: float = 300.0
@export var magnet_range: float = 100.0

var _player: Node2D


func initialize(player: Node2D) -> void:
	_player = player


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	$Visual.visible = false
	var spr := Sprite2D.new()
	spr.texture = preload("res://assets/sprites/xp_gem.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.hframes = 4
	spr.scale = Vector2(1.5, 1.5)
	add_child(spr)
	var anim_tween := create_tween().set_loops()
	for i in 4:
		anim_tween.tween_callback(spr.set.bind("frame", i))
		anim_tween.tween_interval(0.2)
	body_entered.connect(_on_body_entered)

	# Effet de pulsation
	var tween := create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.5, 0.35)
	tween.tween_property(self, "modulate:a", 1.0, 0.35)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var dist := global_position.distance_to(_player.global_position)
	var effective_range := magnet_range
	if _player.has_method("get_magnet_range"):
		effective_range = _player.get_magnet_range()
	if dist < effective_range:
		var dir := global_position.direction_to(_player.global_position)
		position += dir * magnet_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_xp"):
		body.collect_xp(xp_value)
	queue_free()
