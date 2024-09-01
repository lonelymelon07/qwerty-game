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
	$Textures.set_deferred(&"frame", note_type)

static func note_type_to_string(_note_type: NoteType) -> Nullable:
	match _note_type:
		NoteType.FAR_LEFT: return Nullable.some("Q")
		NoteType.LEFT: return Nullable.some("W")
		NoteType.MID_LEFT: return Nullable.some("E")
		NoteType.MID_RIGHT: return Nullable.some("R")
		NoteType.RIGHT: return Nullable.some("T")
		NoteType.FAR_RIGHT: return Nullable.some("Y")
		_: return Nullable.none(TYPE_STRING)

static func string_to_note_type(string: String) -> NoteType:
	match string.capitalize():
		"Q": return NoteType.FAR_LEFT
		"W": return NoteType.LEFT
		"E": return NoteType.MID_LEFT
		"R": return NoteType.MID_RIGHT
		"T": return NoteType.RIGHT
		"Y": return NoteType.FAR_RIGHT
		_: return NoteType.INVALID


class NoteEvent:
	enum { NOTE_EVENT_INVALID, NOTE_EVENT_PLAY_ONCE, NOTE_EVENT_PLAY_DURATION, NOTE_EVENT_CHANGE_METADATA }
	
	var event_type: int
	var data: Variant
	
	func _init(event_type_: int, data_: Variant):
		event_type = event_type_
		data = data_
	
	func _to_string():
		return "NoteEvent{%s,%s}" % [self.event_type, self.data]
