extends Area2D
## Projectile espresso - vole en ligne droite, détruit les ennemis au contact.

@export var speed: float = 500.0
@export var max_range: float = 600.0
@export var damage: float = 1.0

var direction := Vector2.RIGHT
var _distance_traveled := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
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
	queue_free()
