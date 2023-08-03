extends Node2D

@export var note_scene: PackedScene
@export var song_audio: AudioStreamOggVorbis
@export_file("*.txt") var sequence_path: String
var metre: int
var sub_metre: int
var bpm: int
var beat_time: int
var subbeat_time: int
var time: int = 0
var notes: Dictionary
var note_speed: float
var _time_last_frame: int = 0
@onready var screen = get_viewport_rect()


func _ready():
	set_process(false)
	
	$MusicPlayer.stream = song_audio
	
	$Label0.text = "---"
	$Label1.text = "---"
	
	var parser = SequenceParser.new(sequence_path)
	var sequence = parser.parse()
	parser.push_errors()
	
	bpm = sequence.metadata.get("bpm", SequenceParser.DEFAULT_BPM)
	metre = sequence.metadata.get("metre", SequenceParser.DEFAULT_METRE)
	sub_metre = sequence.metadata.get("sub_metre", SequenceParser.DEFAULT_SUB_METRE)
	beat_time = roundi(60_000_000.0 / bpm)
	subbeat_time = roundi(beat_time / float(sub_metre))
	
	notes = vecd_to_timed(sequence.sequence)
	
	for node in get_children():
		if node.is_in_group(&"detector"):
			node.played.connect(_on_detector_played_note)
			
	$StartDelay.wait_time = (beat_time * metre) / 1_000_000
	note_speed = (screen.size.y - $Detector0.position.y) / (beat_time * metre / 1_000_000)
	
	start()
	

func _process(_delta):
	_advance_time()

	var timestamps_to_play = notes.keys().filter(func(k): return k <= time)
	for timestamp in timestamps_to_play:
		for note in notes[timestamp]:
			var spawn_position := Vector2(get_node("Detector%s" % note).position.x, screen.size.y)
			spawn_note(spawn_position, note, note_speed)
		notes.erase(timestamp)


func start():
	print(song_audio.bpm)
	print(song_audio.bar_beats)
	_time_last_frame = Time.get_ticks_usec()
	set_process(true)
	$StartDelay.start()


func spawn_note(spawn_position: Vector2, note_type: BaseNote.NoteType, speed: float):
	var note = note_scene.instantiate()
	note.position = spawn_position
	note.note_type = note_type
	note.speed = speed
	add_child(note)


func vecd_to_timed(vecd: Dictionary):
	var timed := {}
	for k in vecd:
		var newk: int = roundi(((metre*(k.x - 1) + (k.y - 1)) * beat_time) + k.z * subbeat_time)
		timed[newk] = vecd[k]
	return timed



func _advance_time():
	var time_this_frame = Time.get_ticks_usec()
	time += time_this_frame - _time_last_frame
	_time_last_frame = time_this_frame 


func _on_detector_played_note(success):
	$Label0.text = $Detector0.success_to_str(success)
	$Label1.text = $Detector5.success_to_str(success)
	await get_tree().create_timer(0.5).timeout
	$Label0.text = "---"
	$Label1.text = "---"


func _on_start_delay_timeout():
	$MusicPlayer.play()
