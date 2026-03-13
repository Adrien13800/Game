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
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist < magnet_range:
		var dir := global_position.direction_to(_player.global_position)
		position += dir * magnet_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_xp"):
		body.collect_xp(xp_value)
	queue_free()
