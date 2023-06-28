extends Node2D

@export var note_scene: PackedScene
@onready var screen = get_viewport_rect()

func _ready():
	#spawn_sequentially()
	pass

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
	

func spawn_note(position: Vector2, note_type: Note.NoteType):
	var note = note_scene.instantiate()
	note.position = position
	note.note_type = note_type
	add_child(note)

func _process(delta):
	#if Input.is_action_pressed("play_Q"):
	$Label.text = $Detector0.success_to_str($Detector0.get_success())
