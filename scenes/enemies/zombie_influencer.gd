extends "res://scenes/enemies/zombie_client.gd"
## Influenceur zombie - esquive en zigzag, difficile à toucher.

var _time: float = 0.0
@export var zigzag_strength: float = 2.0
@export var zigzag_frequency: float = 3.5


func _setup_sprite() -> void:
	_enemy_sprite = Sprite2D.new()
	_enemy_sprite.texture = preload("res://assets/sprites/zombie_influencer.png")
	_enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_enemy_sprite.hframes = 4
	_enemy_sprite.scale = Vector2(2, 2)
	add_child(_enemy_sprite)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	_time += delta
	var to_player := global_position.direction_to(_target.global_position)
	var perp := Vector2(-to_player.y, to_player.x)
	var zigzag := sin(_time * zigzag_frequency) * zigzag_strength
	var final_dir := (to_player + perp * zigzag).normalized()

	var current_speed := speed * (0.4 if _slow_stacks > 0 else 1.0)
	velocity = final_dir * current_speed
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
