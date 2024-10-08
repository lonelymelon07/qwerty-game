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
var time: int = 0 # us
var notes: Dictionary
var note_speed: float = 0 # px / s (NOT us!!)
var _time_last_frame: int = 0
var seeked_start: int = 0
var note_speed_modifier: float
@onready var screen = get_viewport_rect()

var _t_score: int = 0
var _t_process_count: int = 0

func _ready():
	# DEBUG stuff
	$DebugScreen.property_list = [&"time", &"bpm", &"note_speed", &"metre"] as Array[StringName]
	
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
	
	var start_delay_string: String = sequence.metadata.get("start_delay", "%sb"%metre)
	print(start_delay_string)
	if start_delay_string.ends_with("s"):
		$StartDelay.wait_time = float(start_delay_string.trim_suffix("s"))
	elif start_delay_string.ends_with("b"):
		$StartDelay.wait_time = float(start_delay_string.trim_suffix("b")) * beat_time / 1_000_000.0
	else:
		$StartDelay.wait_time = 0.0
		push_warning("invalid start delay")
	print("start delay wait time %s" % $StartDelay.wait_time)
	
	# get speed of notes : modifier * (distance / time [assuming notes should spawn 1 bar ahead] )
	# NOTE: modifier was complicating things a bit
	note_speed = ((screen.size.y - $Detector0.position.y) / $StartDelay.wait_time)
	
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
				BaseNote.NoteEvent.NOTE_EVENT_PLAY_ONCE:
					var spawn_position := Vector2(get_node("Detector%s" % event.data).position.x, screen.size.y)
					spawn_note(spawn_position, event.data, note_speed)
				BaseNote.NoteEvent.NOTE_EVENT_PLAY_DURATION:
					var spawn_position := Vector2(get_node("Detector%s" % event.data[0]).position.x, screen.size.y)
					spawn_note(spawn_position, event.data[0], note_speed, event.data[1])
				BaseNote.NoteEvent.NOTE_EVENT_CHANGE_METADATA:
					match event.data[0]:
						"bpm": bpm = event.data[1]
						"metre": metre = event.data[1]
		
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


func spawn_note(spawn_position: Vector2, note_type: BaseNote.NoteType, speed: float, duration=0):
	var note = note_scene.instantiate()
	note.position = spawn_position
	note.note_type = note_type
	note.speed = speed
	note.missed.connect(_on_note_miss)
	note.length = roundi(duration * speed / 1_000_000.0)

	add_child(note)


# Converts a Dict with Vector3 keys (bar, beat, subbeat) to a single timestamp key in μs
func vecd_to_timed(vecd: Dictionary):
	print(vecd)
	var timed := {}
	var temp_bpm := bpm
	var temp_metre := metre
	var vec_offset := Vector3i.ZERO # bar, beat subeat offset for changing BPM
	var time_offset := 0

	for k in vecd:
		# Because this calculation assumes a constant BPM, we have to "reset" to 0
		# every time the BPM changes, and add back on that time offset later
		var newk: int = roundi(
			((temp_metre*(k.x - vec_offset.x) + (k.y - vec_offset.y)) * calc_beat_time(temp_bpm)) 
				+ ((k.z - vec_offset.z) * calc_subbeat_time(temp_bpm, sub_metre))
			)

		for event in vecd[k]:
			if event.event_type == BaseNote.NoteEvent.NOTE_EVENT_PLAY_DURATION:
				# IMPORTANT NOTE: This is a DURATION calculation, and also assumes CONSTANT bpm & metre for its length
				event.data[1] = roundi(
						(temp_metre * event.data[1].x + event.data[1].y) * calc_beat_time(temp_bpm)
						+ event.data[1].z * calc_subbeat_time(temp_bpm, sub_metre) 
				)
				print(event.data[1])

		timed[newk + time_offset] = vecd[k]

		for event in vecd[k]:
			if event.event_type == BaseNote.NoteEvent.NOTE_EVENT_CHANGE_METADATA:
				match event.data[0]:
					"bpm": 
						temp_bpm = event.data[1]
					"metre":
						temp_metre = event.data[1]
				vec_offset = k
				time_offset = newk
		
	
	print(timed)
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
