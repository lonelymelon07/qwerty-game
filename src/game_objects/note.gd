extends BaseNote

@export var SPEED = 150


func _physics_process(delta):
	position.y -= SPEED * delta


func _on_screen_exited():
	queue_free()

