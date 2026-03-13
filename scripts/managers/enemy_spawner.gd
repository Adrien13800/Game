extends Node
## Spawne des vagues de clients zombies autour du joueur.

const ZombieScene := preload("res://scenes/enemies/zombie_client.tscn")

@export var spawn_interval: float = 1.2
@export var spawn_distance: float = 600.0

var _player: Node2D
var _timer: Timer


func _ready() -> void:
	_player = get_parent().get_node("Player")

	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_spawn_enemy)


func _spawn_enemy() -> void:
	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * spawn_distance

	var enemy := ZombieScene.instantiate()
	enemy.global_position = _player.global_position + offset
	enemy.initialize(_player)
	get_parent().add_child(enemy)
