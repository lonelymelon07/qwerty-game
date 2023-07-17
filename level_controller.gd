extends Node

# ALL TIME IN us

const NUM_SUBBEATS := 72

var metre: int
var bpm: int
var beat_time: int
var subbeat_time: int

var time_last_frame: int = 0
var time: int = 0
var notes: Dictionary
var is_started: bool = false

func _ready():
	var parser = LevelParser.new("res://level.txt")
	var level = parser.parse()
	print(level)
	
	bpm = level.metadata.bpm
	metre = level.metadata.metre
	beat_time = roundi(60_000_000 / bpm)
	subbeat_time = roundi(beat_time / NUM_SUBBEATS)
	
	notes = vecd_to_timed(level.sequence)
	
	print(parser.get_errors_as_str())

func _process(_delta):
	if is_started:
		_advance_time()

		var timestamps_to_play = notes.keys().filter(func(k): return k <= time)
		if timestamps_to_play:
			print(timestamps_to_play)
		for i in timestamps_to_play:
			spawn_note(notes[i])
			notes.erase(i)

func _advance_time():
	var time_this_frame = Time.get_ticks_usec()
	time += time_this_frame - time_last_frame
	time_last_frame = time_this_frame 

func vecd_to_timed(vecd: Dictionary):
	var timed := {}
	for k in vecd:
		var newk: int = roundi(((metre * (k.x - 1) + (k.y - 1)) * beat_time) + k.z * subbeat_time)
		timed[newk] = vecd[k]
	return timed

