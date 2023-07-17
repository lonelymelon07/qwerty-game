class_name LevelParser extends RefCounted

var text: String
var result: Dictionary = {
	"metadata": {},
	"sequence": {}
}
var errors: Array = []

var _current: int = 0

func _init(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	text = file.get_as_text()
	file.close()

func parse():
	_current = 0
	var lines = text.split("\n")
	
	while _current < len(lines):
		var line = lines[_current].strip_edges()
		if line.begins_with("#") or line.is_empty():
			pass
		elif line.begins_with("!"):
			var item = _parse_item(line.lstrip("!"))
			if item != null:
				result["metadata"][item[0]] = int(item[1]) if item[1].is_valid_int() else item[1]
		else:
			var item = _parse_item(line)
			if item != null:
				result["sequence"][_parse_timestamp(item[0])] = _char_to_notetype(item[1])
		
		_current += 1
		
	return result

func had_error():
	return not errors.is_empty()

func get_errors_as_str():
	var o = ""
	for i in errors:
		o += "level parser error at line %d: %s\n" % [i[0] + 1, i[1]]
	return o if o else "no errors occured during level parsing"
	
func _parse_item(line):
	line = line.strip_edges()
	var split_line = Array(line.split("="))
	
	if len(split_line) != 2:
		errors.append([_current, "invalid key/value pair"])
		return null
	return split_line.map(func(x): return x.strip_edges())
		

func _parse_timestamp(s):
	var nums = s.split(".")
	
	if len(nums) != 3:
		errors.append([_current, "beat position must contain 3 values, eg 1.2.0"])
		return null
	nums = Array(nums).map(func(s): return s.to_int())
	return Vector3i(nums[0], nums[1], nums[2])

func _char_to_notetype(c):
	match c:
		"Q": return Note.NoteType.FAR_LEFT
		"W": return Note.NoteType.LEFT
		"E": return Note.NoteType.MID_LEFT
		"R": return Note.NoteType.MID_RIGHT
		"T": return Note.NoteType.RIGHT
		"Y": return Note.NoteType.FAR_RIGHT
		_:
			errors.append([_current, "invalid NoteType"])
			return null
