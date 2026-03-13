extends CharacterBody2D
## Client zombie - fonce vers le barista, drop de l'XP en mourant.

const XPGemScene := preload("res://scenes/pickups/xp_gem.tscn")

@export var speed: float = 120.0
@export var hp: float = 3.0

var _target: Node2D


func initialize(target: Node2D) -> void:
	_target = target


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_target):
		return

	var direction := global_position.direction_to(_target.global_position)
	velocity = direction * speed
	move_and_slide()


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_drop_xp()
		queue_free()


func _drop_xp() -> void:
	var gem := XPGemScene.instantiate()
	gem.global_position = global_position
	gem.initialize(_target)
	get_parent().add_child(gem)
