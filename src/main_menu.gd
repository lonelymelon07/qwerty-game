extends Control

@onready var tree = get_tree()

func _on_quit_button_pressed():
	tree.quit()


func _on_play_button_pressed():
	SceneLoader.load_scene("res://src/levels/level_1.tscn")


func _on_play_custom_button_pressed():
	if ResourceLoader.exists("res://src/levels/%s.tscn" % $CustomLevelEdit.text):
		SceneLoader.load_scene("res://src/levels/%s.tscn" % $CustomLevelEdit.text)
	else:
		print("Error loading level: level does not exist!")
