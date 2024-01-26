extends Control

@onready var tree = get_tree()

func _on_quit_button_pressed():
	tree.quit()


func _on_play_button_pressed():
	SceneLoader.load_scene("res://src/levels/default_level.tscn")
	var scene = await SceneLoader.loaded
	change_to_level_scene(scene, "res://level.txt", Nullable.none(TYPE_OBJECT))


func _on_play_custom_button_pressed():
	SceneLoader.load_scene("res://src/levels/default_level.tscn")
	var scene: PackedScene = await SceneLoader.loaded
	var audio: AudioStreamOggVorbis = load($CustomLevelContainer/CustomSongEdit.text)
	
	change_to_level_scene(scene, $CustomLevelContainer/CustomLevelEdit.text, Nullable.some(audio))


func change_to_level_scene(level_scene: PackedScene, sequence_path: String, audio_stream: Nullable):
	var level := level_scene.instantiate()
	level.get_node(^"NoteController").sequence_path = sequence_path
	if audio_stream.is_some:
		level.get_node(^"NoteController").song_audio = audio_stream.unwrap(true)
	get_tree().root.add_child(level)
