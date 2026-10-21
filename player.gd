extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const JUMP_TAKEOFF_FRAME = 26.0
const JUMP_TOTAL_FRAMES = 71.0
const JUMP_ANIM_SPEED = 1.0
const JUMP_LAND_FRAME = 41.0

var target_velocity = Vector3.ZERO

@onready var anim: AnimationPlayer = $Pivot/std_walk/AnimationPlayer


func _ready() -> void:
	var lib := AnimationLibrary.new()
	lib.add_animation("walk", load("res://walk.res"))
	lib.add_animation("idle", load("res://idle.res"))
	lib.add_animation("jump", load("res://jump.res"))
	anim.add_animation_library("extra", lib)


func _physics_process(delta: float) -> void:
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		direction.x += 1
	if Input.is_action_pressed("move_back"):
		direction.x -= 1

	# Rotazione
	var look_dir := Vector3.ZERO
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		look_dir = direction
	else:
		var cam := get_viewport().get_camera_3d()
		if cam:
			look_dir = cam.global_position - global_position
			look_dir.y = 0

	if look_dir.length() > 0.001:
		var target_basis := Basis.looking_at(look_dir.normalized(), Vector3.UP, true)
		$Pivot.basis = $Pivot.basis.slerp(target_basis, 10.0 * delta).orthonormalized()

	# Velocità orizzontale
	target_velocity.x = direction.x * SPEED
	target_velocity.z = direction.z * SPEED

	# Velocità verticale
	if not is_on_floor():
		target_velocity.y += get_gravity().y * delta
	elif Input.is_action_just_pressed("jump"):
		target_velocity.y = JUMP_VELOCITY
		anim.play("extra/jump", 0.05)
		anim.seek(anim.current_animation_length * JUMP_TAKEOFF_FRAME / JUMP_TOTAL_FRAMES, true)
		var air_time := 2.0 * JUMP_VELOCITY / absf(get_gravity().y)
		var anim_air_time := anim.current_animation_length * (JUMP_LAND_FRAME - JUMP_TAKEOFF_FRAME) / JUMP_TOTAL_FRAMES
		anim.speed_scale = anim_air_time / air_time
	else:
		target_velocity.y = 0.0

	# Movimento
	velocity = target_velocity
	move_and_slide()
	
	print(is_on_floor(), " ", anim.current_animation)


	# Animazioni
	if is_on_floor() and velocity.y <= 0.0:
		anim.speed_scale = 1.0
		anim.play("extra/walk" if direction != Vector3.ZERO else "extra/idle", 0.2)
