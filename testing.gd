extends Node


func _ready():
	var parser = TempCfgWrapper.new("res://levelcfg.cfg")
	print(parser.parse())
