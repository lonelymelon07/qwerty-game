extends Control


func _ready():
	SceneLoader.load_scene("res://src/levels/default_level.tscn")


func _process(_delta):
	$Label.text = str(SceneLoader.load_progress)
