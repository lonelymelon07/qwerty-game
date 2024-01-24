extends BaseNote

var speed: float

func _ready():
	super._ready()


func _physics_process(delta):
	position.y -= speed * delta
	

func _on_screen_exited():
	queue_free()

