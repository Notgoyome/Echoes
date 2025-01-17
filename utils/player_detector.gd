extends Area2D

signal player_detected(body:Player)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body:Node2D) -> void:
	print("entered")
	if body is Player:
		emit_signal("player_detected", body)
	pass # Replace with function body.
