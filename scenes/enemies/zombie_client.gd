extends CharacterBody2D
## Client zombie - fonce vers le barista, drop de l'XP en mourant.

const XPGemScene := preload("res://scenes/pickups/xp_gem.tscn")

const ENEMY_SPRITES := {
	"student": preload("res://assets/sprites/zombie_student.png"),
	"manager": preload("res://assets/sprites/zombie_manager.png"),
}

@export var speed: float = 120.0
@export var hp: float = 3.0
@export var damage: float = 1.0
@export var xp_value: int = 1
@export var enemy_type: String = "student"


func get_damage() -> float:
	return damage

var _target: Node2D
var _slow_stacks: int = 0
var _enemy_sprite: Sprite2D
var _anim_timer: float = 0.0


func initialize(target: Node2D) -> void:
	_target = target


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 0
	$Visual.visible = false
	_setup_sprite()
	# Pop-in à l'apparition
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _setup_sprite() -> void:
	if ENEMY_SPRITES.has(enemy_type):
		_enemy_sprite = Sprite2D.new()
		_enemy_sprite.texture = ENEMY_SPRITES[enemy_type]
		_enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_enemy_sprite.hframes = 4
		_enemy_sprite.scale = Vector2(2, 2)
		add_child(_enemy_sprite)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	var direction := global_position.direction_to(_target.global_position)
	var current_speed := speed * (0.4 if _slow_stacks > 0 else 1.0)
	velocity = direction * current_speed
	move_and_slide()
	if _enemy_sprite:
		if velocity.x != 0:
			_enemy_sprite.flip_h = velocity.x < 0
		if velocity.length_squared() > 1.0:
			_anim_timer += delta
			if _anim_timer >= 0.15:
				_anim_timer -= 0.15
				_enemy_sprite.frame = (_enemy_sprite.frame + 1) % 4
		else:
			_enemy_sprite.frame = 0
			_anim_timer = 0.0


func apply_slow() -> void:
	_slow_stacks += 1


func remove_slow() -> void:
	_slow_stacks = max(0, _slow_stacks - 1)


func take_damage(amount: float) -> void:
	hp -= amount
	if is_instance_valid(_target):
		_target.add_damage(amount)
	if hp <= 0:
		if is_instance_valid(_target):
			_target.add_kill()
		_death_effect()
		_drop_xp()
		_maybe_drop_tip()
		queue_free()
	else:
		_hit_flash()


func _hit_flash() -> void:
	modulate = Color(3, 3, 3, 1)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.12)



func _death_effect() -> void:
	var particles := CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.35
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.direction = Vector2.ZERO
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 90.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = $Visual.color

	var cleanup := Timer.new()
	cleanup.wait_time = 0.5
	cleanup.one_shot = true
	cleanup.autostart = true
	cleanup.timeout.connect(particles.queue_free)
	particles.add_child(cleanup)

	get_parent().call_deferred("add_child", particles)


func _drop_xp() -> void:
	var gem := XPGemScene.instantiate()
	gem.global_position = global_position
	gem.xp_value = xp_value
	gem.initialize(_target)
	get_parent().call_deferred("add_child", gem)


func _maybe_drop_tip() -> void:
	if randf() < 0.1:
		GlobalStats.add_tips(1)
