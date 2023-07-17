extends Node2D

const NUM_SUBBEATS := 72

@export var note_scene: PackedScene
@onready var screen = get_viewport_rect()

var metre: int
var bpm: int
var beat_time: int
var subbeat_time: int

var time_last_frame: int = 0
var time: int = 0
var notes: Dictionary
var is_started: bool = false

func _ready():
	set_process(false)
	var parser = LevelParser.new("res://level.txt")
	var level = parser.parse()
	print(level)
	
	bpm = level.metadata.bpm
	metre = level.metadata.metre
	beat_time = roundi(60_000_000 / bpm)
	subbeat_time = roundi(beat_time / NUM_SUBBEATS)
	
	notes = vecd_to_timed(level.sequence)
	
	print(parser.get_errors_as_str())
	
	time_last_frame = Time.get_ticks_usec()
	set_process(true)

func spawn_sequentially():
	$Timer.start()
	var spawn_position = Vector2(0, screen.size.y)
	var note := 0
	while true:
		note = randi() % 6
		spawn_position.x = get_node("Detector%s" % note).position.x
		await $Timer.timeout
		spawn_note(spawn_position, note)
		$Timer.wait_time = randf()
	

func spawn_note(spawn_position: Vector2, note_type: Note.NoteType):
	var note = note_scene.instantiate()
	note.position = spawn_position
	note.note_type = note_type
	add_child(note)

func _process(_delta):
	$Label.text = str(time)
	
	_advance_time()

	var timestamps_to_play = notes.keys().filter(func(k): return k <= time)
	if timestamps_to_play:
		print(timestamps_to_play)
		print(_delta)
	for i in timestamps_to_play:
		var spawn_position = Vector2(
			get_node("Detector%s" % notes[i]).position.x,
			screen.size.y
		)
		spawn_note(spawn_position, notes[i])
		notes.erase(i)

func _on_level_controller_spawn_note(type):
	var spawn_position = Vector2(
		get_node("Detector%s" % type).position.x,
		screen.size.y
	)
	spawn_note(spawn_position, type)

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
