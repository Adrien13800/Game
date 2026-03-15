extends Node
## Spawne des vagues d'ennemis variés avec difficulté progressive.

const StudentScene := preload("res://scenes/enemies/zombie_client.tscn")
const ManagerScene := preload("res://scenes/enemies/zombie_manager.tscn")
const InfluencerScene := preload("res://scenes/enemies/zombie_influencer.tscn")
const BossScene := preload("res://scenes/enemies/zombie_boss.tscn")

@export var spawn_interval: float = 1.2
@export var min_spawn_interval: float = 0.25
@export var spawn_distance: float = 600.0
@export var boss_interval: float = 180.0

var _player: Node2D
var _timer: Timer
var _boss_timer: Timer
var _time_elapsed: float = 0.0
var _boss_count: int = 0
var current_boss: Node2D = null


func _ready() -> void:
	_player = get_parent().get_node("Player")

	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_spawn_wave)

	_boss_timer = Timer.new()
	_boss_timer.wait_time = boss_interval
	_boss_timer.autostart = true
	add_child(_boss_timer)
	_boss_timer.timeout.connect(_spawn_boss)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_time_elapsed += delta
	_timer.wait_time = max(min_spawn_interval, spawn_interval - _time_elapsed * 0.015)


func _pick_enemy_type(minutes: float) -> PackedScene:
	# Étudiants dès le début, managers à 1min, influenceurs à 2min
	var pool: Array[PackedScene] = [StudentScene]
	if minutes >= 1.0:
		pool.append(ManagerScene)
	if minutes >= 2.0:
		pool.append(InfluencerScene)
	return pool[randi() % pool.size()]


func _spawn_wave() -> void:
	var minutes := _time_elapsed / 60.0
	var count := mini(1 + int(minutes / 2.0), 5)

	for i in count:
		var scene := _pick_enemy_type(minutes)
		var enemy := scene.instantiate()

		# Scaling proportionnel aux stats de base
		var hp_mult := 1.0 + minutes * 0.3
		var spd_mult := 1.0 + minutes * 0.03
		enemy.hp *= hp_mult
		enemy.speed = minf(enemy.speed * spd_mult, 250.0)
		enemy.damage += minutes * 0.15

		var angle := randf() * TAU
		var offset := Vector2(cos(angle), sin(angle)) * spawn_distance
		enemy.global_position = _player.global_position + offset
		enemy.initialize(_player)
		get_parent().add_child(enemy)


func _spawn_boss() -> void:
	if is_instance_valid(current_boss):
		return
	_boss_count += 1
	var boss := BossScene.instantiate()

	# Scaling par boss successif
	boss.hp *= 1.0 + (_boss_count - 1) * 0.5
	boss.damage += _boss_count * 0.5
	boss.xp_value += _boss_count * 5

	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * spawn_distance
	boss.global_position = _player.global_position + offset
	boss.initialize(_player)
	boss.boss_defeated.connect(_on_boss_defeated)
	current_boss = boss
	get_parent().add_child(boss)


func _on_boss_defeated() -> void:
	current_boss = null
