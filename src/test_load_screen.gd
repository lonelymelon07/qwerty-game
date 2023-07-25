extends Control


func _ready():
	SceneLoader.load_scene("res://src/levels/level_1.tscn")


func _process(_delta):
	$Label.text = str(SceneLoader.load_progress)
