class_name TempCfgWrapper
extends RefCounted

var text: String
var path: String


func _init(file_path: String) -> void:
	path = file_path
	var temp_file = FileAccess.open(path, FileAccess.READ)
	text = temp_file.get_as_text()
	print(path)

func _replace_str_with_enum() -> void:
	var regex = RegEx.new()
	regex.compile("(?i)(?:(?:\\d+\\.)+\\d+\\s?=\\s?)((?<note>[qwerty\\s]\\b))+")
	#(?i)(?:(?:\d+\.)+\d+\s?=\s?)(?<note>([qwerty\s]\b)+)
	for m in regex.search_all(text):
		print(">?")
		print(m.get_string("note"))
		text[m.get_start("note")] = str(BaseNote.string_to_note_type(m.get_string("note")))

func parse() -> Dictionary:
	_replace_str_with_enum()
	print(text)
	var file = ConfigFile.new()
	file.parse(text)
	
	var ret := {metadata={}, sequence={}}
	for key in file.get_section_keys("sequence"):
		ret.sequence[_parse_timestamp(key)] = [file.get_value("sequence", key, BaseNote.NoteType.INVALID)]
	
	for key in file.get_section_keys("metadata"):
		ret.metadata[key] = file.get_value("metadata", key)

	return ret



func _parse_timestamp(s: String): # -> Vector3i | null
	var nums = s.split(".")
	
	if len(nums) != 3:
		return null
	nums = Array(nums).map(func(s): return s.to_int())
	return Vector3i(nums[0], nums[1], nums[2])
