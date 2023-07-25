extends BaseNote

enum Success {MISS, OK, GOOD, PERFECT}


func _process(_delta):
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


