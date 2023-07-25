class_name SequenceParser
extends RefCounted

const DEFAULT_BPM := 120
const DEFAULT_METRE := 4
const DEFAULT_SUB_METRE := 72

var text: String
var result: Dictionary = {
	metadata = {},
	sequence = {},
}
var errors: Array[Array] = []
var _current := 0
var path: String

func _init(file_path: String):
	path = file_path
	var file = FileAccess.open(path, FileAccess.READ)
	text = file.get_as_text()
	file.close()


func parse() -> Dictionary:
	_current = 0
	var lines = text.split("\n")
	
	while _current < len(lines):
		var line = lines[_current].strip_edges()
		if line.begins_with("#") or line.is_empty():
			pass
		elif line.begins_with("$"):
			var item = _parse_item(line.lstrip("$"))
			if item != null:
				result.metadata[item[0]] = int(item[1]) if item[1].is_valid_int() else item[1]
		else:
			var item = _parse_item(line)
			if item != null:
				result.sequence[_parse_timestamp(item[0])] = _char_to_notetype(item[1])
		
		_current += 1

	return result


func had_error():
	return not errors.is_empty()


func get_errors_as_str() -> String:
	var o = ""
	for i in errors:
		o += "sequence parser error at line %d: %s\n" % [i[0] + 1, i[1]]
	return o if o else "no errors occured during sequence parsing"


func push_errors():
	for e in errors:
		push_error("error parsing %s at line %d: %s\n" % [path, e[0] + 1, e[1]])


func _parse_item(line: String): # -> Array | null
	line = line.strip_edges()
	var split_line = Array(line.split("="))
	
	if len(split_line) != 2:
		errors.append([_current, "invalid key/value pair"])
		return null
	return split_line.map(func(x): return x.strip_edges())
		

func _parse_timestamp(s): # -> Array | null
	var nums = s.split(".")
	
	if len(nums) != 3:
		errors.append([_current, "beat position must contain 3 values, eg 1.2.0"])
		return null
	nums = Array(nums).map(func(s): return s.to_int())
	return Vector3i(nums[0], nums[1], nums[2])


func _char_to_notetype(c) -> BaseNote.NoteType:
	match c:
		"Q": return BaseNote.NoteType.FAR_LEFT
		"W": return BaseNote.NoteType.LEFT
		"E": return BaseNote.NoteType.MID_LEFT
		"R": return BaseNote.NoteType.MID_RIGHT
		"T": return BaseNote.NoteType.RIGHT
		"Y": return BaseNote.NoteType.FAR_RIGHT
		_:
			errors.append([_current, "invalid NoteType"])
			return BaseNote.NoteType.INVALID
