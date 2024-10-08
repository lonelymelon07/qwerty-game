extends Control

@onready var tree = get_tree()

func _ready():
	$CustomLevelContainer/CustomLevelEdit.text = Persistent.main_menu_data.custom_level_edit_text
	$CustomLevelContainer/CustomSongEdit.text = Persistent.main_menu_data.custom_song_edit_text
	
	if Persistent.config.debug.instant_load_default_level:
		_on_play_button_pressed()
	elif Persistent.config.debug.instant_load_custom_level:
		$CustomLevelContainer/CustomLevelEdit.text = Persistent.config.debug.custom_sequence_path
		$CustomLevelContainer/CustomSongEdit.text = Persistent.config.debug.custom_audio_path
		_on_play_custom_button_pressed()


func _on_quit_button_pressed():
	tree.quit()


func _on_play_button_pressed():
	SceneLoader.load_scene("res://src/levels/base_test_level.tscn")
	var scene = await SceneLoader.loaded
	change_to_level_scene(scene, "res://level.txt", Nullable.none(TYPE_OBJECT))


func _on_play_custom_button_pressed():
	if len($CustomLevelContainer/CustomLevelEdit.text) == 0:
		$CustomLevelContainer/CustomLevelEdit.text = Persistent.config.debug.custom_sequence_path
	if len($CustomLevelContainer/CustomSongEdit.text) == 0:
		$CustomLevelContainer/CustomSongEdit.text = Persistent.config.debug.custom_audio_path
	
	SceneLoader.load_scene("res://src/levels/base_test_level.tscn")
	var scene: PackedScene = await SceneLoader.loaded
	var audio: AudioStreamOggVorbis = load($CustomLevelContainer/CustomSongEdit.text)
	
	change_to_level_scene(scene, $CustomLevelContainer/CustomLevelEdit.text, Nullable.some(audio))


func change_to_level_scene(level_scene: PackedScene, sequence_path: String, audio_stream: Nullable):
	var level := level_scene.instantiate()
	level.get_node(^"NoteController").sequence_path = sequence_path
	if audio_stream.is_some:
		level.get_node(^"NoteController").song_audio = audio_stream.unwrap(true)
	
	level.get_node(^"NoteController").seeked_start = roundi(Persistent.config.debug.start_song_from_s * 1_000_000)
	
	Persistent.main_menu_data.custom_level_edit_text = $CustomLevelContainer/CustomLevelEdit.text
	Persistent.main_menu_data.custom_song_edit_text = $CustomLevelContainer/CustomSongEdit.text
	
	tree.root.add_child(level)
