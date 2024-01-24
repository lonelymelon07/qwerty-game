extends Control

@onready var tree = get_tree()

func _on_quit_button_pressed():
	tree.quit()


func _on_play_button_pressed():
	SceneLoader.load_scene("res://src/levels/default_level.tscn")
	var scene = await SceneLoader.loaded
	change_to_level_scene(scene, "res://level.txt")


func _on_play_custom_button_pressed():
	SceneLoader.load_scene("res://src/levels/default_level.tscn")
	var scene = await SceneLoader.loaded
	change_to_level_scene(scene, $CustomLevelContainer/CustomLevelEdit.text)


func change_to_level_scene(level_scene: PackedScene, sequence_path: String):
	var level := level_scene.instantiate()
	level.get_node(^"NoteController").sequence_path = sequence_path
	get_tree().root.add_child(level)
