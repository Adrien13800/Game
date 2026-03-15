extends Area2D
## Projectile espresso - vole en ligne droite, détruit les ennemis au contact.

@export var speed: float = 500.0
@export var max_range: float = 600.0
@export var damage: float = 1.0
@export var pierce: int = 1

var direction := Vector2.RIGHT
var _distance_traveled := 0.0
var _pierce_left: int = 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_pierce_left = pierce
	$Visual.visible = false
	var spr := Sprite2D.new()
	spr.texture = preload("res://assets/sprites/espresso_shot.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.hframes = 4
	spr.scale = Vector2(1.5, 1.5)
	spr.flip_h = direction.x < 0
	add_child(spr)
	var anim_tween := create_tween().set_loops()
	for i in 4:
		anim_tween.tween_callback(spr.set.bind("frame", i))
		anim_tween.tween_interval(0.08)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	position += movement
	_distance_traveled += movement.length()

	if _distance_traveled >= max_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_pierce_left -= 1
	if _pierce_left <= 0:
		queue_free()
