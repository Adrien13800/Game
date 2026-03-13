extends CharacterBody2D
## Barista - déplacement, tir auto, système d'XP et level up.

signal leveled_up

const EspressoScene := preload("res://scenes/weapons/espresso_shot.tscn")

@export var speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1800.0
@export var fire_rate: float = 0.4
@export var espresso_damage: float = 1.0
@export var espresso_range: float = 600.0
@export var espresso_speed: float = 500.0

var facing_direction := Vector2.RIGHT
var current_xp: int = 0
var current_level: int = 1
var xp_for_next_level: int = 5
var _fire_timer: Timer


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_fire_timer = Timer.new()
	_fire_timer.wait_time = fire_rate
	_fire_timer.autostart = true
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_shoot)


func _physics_process(delta: float) -> void:
	var direction := _get_input_direction()

	if direction != Vector2.ZERO:
		facing_direction = direction
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()


func _shoot() -> void:
	var shot := EspressoScene.instantiate()
	shot.direction = facing_direction
	shot.global_position = global_position
	shot.damage = espresso_damage
	shot.max_range = espresso_range
	shot.speed = espresso_speed
	get_parent().add_child(shot)


func collect_xp(amount: int) -> void:
	current_xp += amount
	if current_xp >= xp_for_next_level:
		current_xp -= xp_for_next_level
		current_level += 1
		xp_for_next_level = int(xp_for_next_level * 1.4)
		leveled_up.emit()


func update_fire_timer() -> void:
	_fire_timer.wait_time = fire_rate


func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0

	return dir.normalized()
