extends Node2D

class_name Note

@export var SPEED = 150
@export_range(0, len(NoteType) - 1) var note_type: NoteType = 0

enum NoteType {FAR_LEFT, LEFT, MID_LEFT, MID_RIGHT, RIGHT, FAR_RIGHT}

func _ready():
	$Textures.frame = note_type

func _physics_process(delta):
	position.y -= SPEED * delta

func _on_screen_exited():
	queue_free()
