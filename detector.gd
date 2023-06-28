extends Node

@export_range(0, len(Note.NoteType) - 1) var note_type: Note.NoteType = 0

enum Success {MISS, OK, GOOD, PERFECT}

func _process(delta):
	var key = "play_%s"
	match note_type:
		5: key %= "Y"
		4: key %= "T"
		3: key %= "R"
		2: key %= "E"
		1: key %= "W"
		_: key %= "Q"
	if Input.is_action_pressed(key):
		$Textures.animation = "highlighted"
	else:
		$Textures.animation = "default"
	$Textures.frame = note_type

func _ready():
	$Textures.animation = "default"
	$Textures.frame = note_type

func get_success() -> Success:
	if $Perfect.has_overlapping_areas():
		return Success.PERFECT
	if $Good.has_overlapping_areas():
		return Success.GOOD
	if $OK.has_overlapping_areas():
		return Success.OK
	
	return Success.MISS

func success_to_str(success: Success) -> String:
	match success:
		Success.MISS:
			return "miss"
		Success.OK:
			return "ok"
		Success.GOOD:
			return "good"
		Success.PERFECT:
			return "perfect"
		_:
			return "invalid"

func _on_textures_animation_changed():
	$Textures.frame = note_type
