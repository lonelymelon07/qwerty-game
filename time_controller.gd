extends Node2D

# ALL TIME IN us

const NUM_SUBBEATS := 72

@export var metre: int = 4
@export var bpm: int = 60

var beat_time := roundi(60_000_000 / bpm)
var subbeat_time := roundi(beat_time / NUM_SUBBEATS)

var time_last_frame: int
var time: int
var note_count: int

signal spawn_note(type)

func _ready():
	print(beat_time)
	print(subbeat_time)
	
	var vecd = {
		Vector3i(1, 1, 0): "0",
		Vector3i(1, 2, 0): "1M us",
		Vector3i(1, 2, 1): "1M+ us",
		Vector3i(4, 2, 56): "cba"
	}
	
	print(vecd_to_timed(vecd))

func _process(_delta):
	# advance time
	var time_now = Time.get_ticks_usec()
	time += time_now - time_last_frame
	time_last_frame = time_now
	
	var timed = {}
	if timed[]
	
	$Label.text = str(time)

func vecd_to_timed(vecd: Dictionary):
	var timed := {}
	for k in vecd:
		var newk: int = roundi(((4 * (k.x - 1) + (k.y - 1)) * beat_time) + k.z * subbeat_time)
		timed[newk] = vecd[k]
	return timed
