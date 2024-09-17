extends BaseNote

signal missed

var speed: float
var duration: int = 1

func _ready():
	super._ready()
	$ExtendTexture.size.y = duration 


func _physics_process(delta):
	position.y -= speed * delta
	
	if not $Collision.monitorable:
		queue_free()


func _on_screen_exited():
	missed.emit()
	queue_free()

