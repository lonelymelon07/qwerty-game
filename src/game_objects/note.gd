extends BaseNote

signal missed

var speed: float
var length: int = 0

func _ready():
	super._ready()
	$ExtendTexture.size.y = length
	$VisibleOnScreenNotifier2D.rect.size.y = 35 + length
	$NoteEndCollision/CollisionShape2D.position.y = length
	
	if not length:
		$NoteEndCollision.monitorable = false
	


func _physics_process(delta):
	position.y -= speed * delta
	
	if not ($Collision.monitorable or $NoteEndCollision.monitorable):
		queue_free()


func _on_screen_exited():
	missed.emit()
	queue_free()

