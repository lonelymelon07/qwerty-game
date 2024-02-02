extends BaseNote

signal missed

var speed: float

func _ready():
	super._ready()


func _physics_process(delta):
	position.y -= speed * delta
	
	if not $Collision.monitorable:
		queue_free()


func _on_screen_exited():
	missed.emit()
	queue_free()

