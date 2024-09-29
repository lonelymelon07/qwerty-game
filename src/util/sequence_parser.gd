class_name SequenceParser
extends RefCounted

const DEFAULT_BPM := 120
const DEFAULT_METRE := 4
const DEFAULT_SUB_METRE := 72
const DEFAULT_NOTE_SPEED_MODIFIER := 1.0

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
			if item.is_some:
				item = item.unwrap()
				result.metadata[item[0]] = ( # mmmmm tasty multi-line nested ternary
						int(item[1]) if item[1].is_valid_int()
						else float(item[1]) if item[1].is_valid_float() 
						else item[1] # cast if we can, else default to a string
				)
		else:
			var item = _parse_item(line)
			if item.is_some:
				item = item.unwrap()
				var timestamp = _parse_timestamp(item[0]).unwrap(true)
				if not result.sequence.has(timestamp):
					result.sequence[timestamp] = []
				result.sequence[timestamp].append(_str_to_event(item[1]))


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


func _parse_item(line: String) -> Nullable: # -> Array | null
	line = line.strip_edges()
	var split_line = Array(line.split("="))
	
	if len(split_line) != 2:
		errors.append([_current, "invalid key/value pair"])
		return Nullable.none(TYPE_ARRAY)
	return Nullable.some(split_line.map(func(x): return x.strip_edges()))


func _parse_timestamp(s: String) -> Nullable: # -> Vector3i | null
	var nums = s.split(".")
	
	if len(nums) != 3:
		errors.append([_current, "beat position must contain 3 values, eg 1.2.0"])
		return Nullable.none(TYPE_VECTOR3I)
	nums = Vector3i(nums[0].to_int() - 1, nums[1].to_int() - 1, nums[2].to_int())
	return Nullable.some(nums)


#func _char_to_notetype(c: String) -> Variant:
#	var nt = BaseNote.string_to_note_type(c)
#	if nt != BaseNote.NoteType.INVALID:
#		return nt
#	if c.begins_with("!bpm:"):
#		c = c.trim_prefix("!bpm:")
#		if not c.is_valid_int():
#			errors.append([_current, "bpm must be valid int"])
#		return int(c)
#	return BaseNote

func _str_to_event(s: String) -> BaseNote.NoteEvent:
	# let's try metdatering first
	
	var event_type: int
	var data: Variant
	
	s = s.replace(" ", "") # removing all spaces
	if s.contains(":"):
		event_type = BaseNote.NoteEvent.NOTE_EVENT_CHANGE_METADATA
		data = Array(s.split(":"))
		if data[1].is_valid_int():
			data[1] = int(data[1])
	elif s.contains("~"):
		event_type = BaseNote.NoteEvent.NOTE_EVENT_PLAY_DURATION
		data = Array(s.split("~"))
		data[0] = BaseNote.string_to_note_type(data[0])
		var nums: PackedStringArray = data[1].split(".")
		print(nums)
		
		if len(nums) == 2:
			data[1] = Vector3i(0, nums[0].to_int(), nums[1].to_int())
			print(data[1])
		else:
			data[1] = Vector3i(0, nums[0].to_int(), 0)
		
	else:
		event_type = BaseNote.NoteEvent.NOTE_EVENT_PLAY_ONCE
		data = BaseNote.string_to_note_type(s)
		if data == BaseNote.NoteType.INVALID:
			errors.append([_current, "invalid note type"])
	
	return BaseNote.NoteEvent.new(
			event_type,
			data
		)
