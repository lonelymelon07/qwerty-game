class_name BaseNote
extends Node2D

enum NoteType {FAR_LEFT, LEFT, MID_LEFT, MID_RIGHT, RIGHT, FAR_RIGHT, INVALID = -1}

@export var note_type: NoteType

func _ready():
	var animsprites := get_children().filter(func(node): return node is AnimatedSprite2D)
	
	if len(animsprites) != 1:
		var error_msg := "Wrong number of AmimatedSprite2D children. Found %d; expected 1" % len(animsprites)
		if Engine.is_editor_hint():
			push_warning(error_msg)
		else:
			push_error(error_msg)
	
	var textures: AnimatedSprite2D = animsprites[0]
	textures.frame = note_type
	textures.animation_changed.connect(_on_textures_animation_changed)


func _on_textures_animation_changed():
	$Textures.set_deferred("frame", note_type)
