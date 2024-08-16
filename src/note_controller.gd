extends Node2D

@export var note_scene: PackedScene
@export var song_audio: AudioStreamOggVorbis
@export_file("*.txt") var sequence_path: String
var metre: int
var sub_metre: int
var bpm: int
var beat_time: int:
	get: return calc_beat_time(bpm)
var subbeat_time: int:
	get: return calc_subbeat_time(bpm, sub_metre)
var time: int = 0
var notes: Dictionary
var note_speed: float:
	# m * ( dy / (beat_length * metre = bar_length) )  
	get: return note_speed_modifier * ((screen.size.y - $Detector0.position.y) / (beat_time * metre / 1_000_000.0))
var _time_last_frame: int = 0
var seeked_start: int = 0
var note_speed_modifier: float
@onready var screen = get_viewport_rect()

var _t_score: int = 0
var _t_process_count: int = 0

func _ready():
	
	set_process(false)
	
	$MusicPlayer.stream = song_audio
	if Persistent.config.debug.mute_audio:
		$MusicPlayer.volume_db = -300.0
	
	var parser = SequenceParser.new(sequence_path)
	var sequence = parser.parse()
	parser.push_errors()
	
	bpm = sequence.metadata.get("bpm", SequenceParser.DEFAULT_BPM)
	metre = sequence.metadata.get("metre", SequenceParser.DEFAULT_METRE)
	sub_metre = sequence.metadata.get("sub_metre", SequenceParser.DEFAULT_SUB_METRE)
	note_speed_modifier = sequence.metadata.get("note_speed_modifier", SequenceParser.DEFAULT_NOTE_SPEED_MODIFIER)
	
	notes = vecd_to_timed(sequence.sequence)
	
	# Connect detector signals
	for node in get_children():
		if node.is_in_group(&"detector"):
			node.played.connect(_on_detector_played_note)
			
	$StartDelay.wait_time = ((beat_time * metre) / 1_000_000.0) / note_speed_modifier
	
	# get speed of notes : modifier * (distance / time [assuming notes should spawn 1 bar ahead] )
#	note_speed = note_speed_modifier * ((screen.size.y - $Detector0.position.y) / (beat_time * metre / 1_000_000.0))
	
	for animation in $SuccessIndicator.sprite_frames.get_animation_names():
		$SuccessIndicator.sprite_frames.set_animation_speed(animation, 4 * bpm / 60.0)
	$SuccessIndicator.animation = "miss"
	$SuccessIndicator.play()
	
	start()


func _process(_delta):
	_advance_time()
	
	# Get all notes which need to be played
	var timestamps_to_play: Array = notes.keys().filter(func(k): return k <= time)
	
	# Spawn each in the right spot!
	for timestamp in timestamps_to_play:
		for event in notes[timestamp]:
			match event.event_type:
				BaseNote.NoteEvent.NOTE_EVENT_PLAY:
					var spawn_position := Vector2(get_node("Detector%s" % event.data).position.x, screen.size.y)
					spawn_note(spawn_position, event.data, note_speed)
				BaseNote.NoteEvent.NOTE_EVENT_CHANGE_METADATA:
					match event.data[0]:
						"bpm": bpm = event.data[1]
		
		notes.erase(timestamp)
	
	if Input.is_action_just_pressed("ui_cancel"):
		_on_music_player_finished()
	
	$ScoreLabel.text = str(_t_score)
	_t_process_count += 1


func start():
	_time_last_frame = Time.get_ticks_usec()
	
	# We're skipping ahead, so let's purge any notes we don't need
	var timestamps_to_erase = notes.keys().filter(func(k): return k < seeked_start)
	for k in timestamps_to_erase:
		notes.erase(k)

	time = seeked_start

	set_process(true)
	$StartDelay.start()


func spawn_note(spawn_position: Vector2, note_type: BaseNote.NoteType, speed: float):
	var note = note_scene.instantiate()
	note.position = spawn_position
	note.note_type = note_type
	note.speed = speed
	note.missed.connect(_on_note_miss)
	add_child(note)


# Converts a Dict with Vector3 keys (bar, beat, subbeat) to a single timestamp key in μs
func vecd_to_timed(vecd: Dictionary):
	print(vecd)
	var timed := {}
	var temp_bpm := bpm

	print(temp_bpm)

	for k in vecd:
		for event in vecd[k]:
			if event.event_type == BaseNote.NoteEvent.NOTE_EVENT_CHANGE_METADATA:
				print("herefirst")
				match event.data[0]:
					"bpm": 
						temp_bpm = event.data[1]
						print("here??")
		var newk: int = roundi(
			((metre*(k.x - 1) + (k.y - 1)) * calc_beat_time(temp_bpm)) 
				+ k.z * calc_subbeat_time(temp_bpm, sub_metre)
			)
		timed[newk] = vecd[k]
	#		elif vecd[k].type == SequenceParser.SongEvent.EVENT_TYPE_CHANGE_METADATA:
	#			match vecd[k]:
	#				"bpm": bpm = vecd[k].data[0]
	
	print(temp_bpm)
	return timed


func _advance_time():
	var time_this_frame = Time.get_ticks_usec()
	time += time_this_frame - _time_last_frame
	_time_last_frame = time_this_frame



func _on_detector_played_note(success):
	$SuccessIndicator.play($Detector0.success_to_str(success))
	
	_t_score += success if success else -1 # 0 == Miss, >=1 is a hit


func _on_start_delay_timeout():
	$MusicPlayer.play(seeked_start / 1_000_000.0)


func _on_music_player_finished():
	print(bpm)
	
	print("finished: avg process delta: %d us" % (Time.get_ticks_usec() / _t_process_count))
	get_tree().change_scene_to_file("res://src/main_menu.tscn")
	set_process(false)
	get_parent().queue_free()

func _on_note_miss():
	_t_score -= 1

static func calc_beat_time(bpm_: int):
	return roundi(60_000_000.0 / bpm_)

static func calc_subbeat_time(bpm_: int, sub_metre_: int):
	return roundi(calc_beat_time(bpm_) / float(sub_metre_))
