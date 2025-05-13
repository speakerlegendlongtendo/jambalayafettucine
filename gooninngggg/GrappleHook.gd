extends Area2D

@export var speed := 1500.0
var direction := Vector2.RIGHT
@export var player: CharacterBody2D
var stopped := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)  # Connect signal

func _physics_process(delta: float) -> void:
	if stopped:
		return
	
	position += direction * speed * delta
	if player && global_position.distance_to(player.global_position) > player.grapple_max_length:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("grapple_point"):
		player.connect_grapple(global_position)
		queue_free()
	elif body != player:
		queue_free()
