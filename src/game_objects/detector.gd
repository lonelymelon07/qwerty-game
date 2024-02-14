extends BaseNote

enum Success { MISS, OK, GOOD, PERFECT }

signal played(success: Success)

var key: StringName


func _ready():
	# child functions override parent ones!
	super._ready()
	key = &"play_%s"
	match note_type:
		5: key %= "Y"
		4: key %= "T"
		3: key %= "R"
		2: key %= "E"
		1: key %= "W"
		_: key %= "Q"


func _process(_delta):
	if Input.is_action_pressed(key):
		$Textures.animation = &"highlighted"
	else:
		$Textures.animation = &"default"
	
	if Input.is_action_just_pressed(key):
		_find_overlapping_areas().map(func(s): played.emit(s))


func _get_success(area: Area2D) -> Success:
	if $Perfect.overlaps_area(area):
		return Success.PERFECT
	if $Good.overlaps_area(area):
		return Success.GOOD
	if $OK.overlaps_area(area):
		return Success.OK
	
	return Success.MISS


func _find_overlapping_areas() -> Array[Success]:
	var areas: Array[Area2D] = $OK.get_overlapping_areas()
	var result: Array[Success] = []
	for area in areas:
		if area.monitorable:
			area.monitorable = false
			result.append(_get_success(area))
	if len(result) == 0:
		result.append(Success.MISS)
	return result

static func success_to_str(success: Success) -> String:
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


