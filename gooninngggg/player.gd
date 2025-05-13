extends CharacterBody2D

# Movement variables
@export var max_speed := 600.0
@export var acceleration := 1500.0
@export var friction := 2000.0
@export var air_resistance := 500.0
@export var gravity := 2000.0
@export var jump_force := 700.0
@export var fast_fall_gravity := 3000.0

# Grapple variables
var grapple_joint: PinJoint2D = null
var grappling := false
var grapple_point := Vector2.ZERO
@export var grapple_max_length := 500.0
@export var grapple_pull_force := 1500.0

# State variables
var fast_falling := false
@export var coyote_time := 0.1
var coyote_timer := 0.0
@export var jump_buffer_time := 0.1
var jump_buffer_timer := 0.0

@onready var hook_scene := preload("res://GrappleHook.tscn")
@onready var raycast := $RayCast2D

func _physics_process(delta: float) -> void:
	handle_input()
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	handle_grapple(delta)
	
	move_and_slide()
	
	update_coyote_time(delta)
	update_jump_buffer(delta)

func handle_input() -> void:
	if Input.is_action_just_pressed("grapple"):
		fire_grapple()
	if Input.is_action_just_released("grapple"):
		release_grapple()

func apply_gravity(delta: float) -> void:
	var current_gravity = fast_fall_gravity if fast_falling else gravity
	if not is_on_floor():
		velocity.y += current_gravity * delta

func handle_movement(delta: float) -> void:
	var input := Input.get_axis("move_left", "move_right")
	
	if input != 0:
		var accel = acceleration if is_on_floor() else air_resistance
		velocity.x = move_toward(velocity.x, input * max_speed, accel * delta)
	else:
		var decel = friction if is_on_floor() else air_resistance
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
		
	if can_jump() and jump_buffer_timer > 0:
		velocity.y = -jump_force
		coyote_timer = 0.0
		jump_buffer_timer = 0.0

func can_jump() -> bool:
	return is_on_floor() or coyote_timer > 0.0

func update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)

func update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

func fire_grapple() -> void:
	if grappling:
		return
	
	var hook: Area2D = hook_scene.instantiate()
	# Explicit type conversion
	hook.set("player", self as CharacterBody2D)
	hook.direction = (get_global_mouse_position() - global_position).normalized()
	get_parent().add_child(hook)
	grappling = true

func release_grapple() -> void:
	if grapple_joint:
		grapple_joint.queue_free()
		grapple_joint = null
	grappling = false

func handle_grapple(delta: float) -> void:
	if grapple_joint:
		var direction_to_point := (grapple_point - global_position).normalized()
		velocity += direction_to_point * grapple_pull_force * delta
		velocity = velocity.limit_length(max_speed * 1.5)

func connect_grapple(point: Vector2) -> void:
	grapple_point = point
	grapple_joint = PinJoint2D.new()
	grapple_joint.position = grapple_point
	get_parent().add_child(grapple_joint)
	grapple_joint.node_a = grapple_joint.get_path_to(self)
	grapple_joint.node_b = grapple_joint.get_path_to(get_parent())
