extends Control

func _ready():
	SceneLoader.load_scene("res://main.tscn")

func _process(_delta):
	$Label.text = str(SceneLoader.load_progress[0])
