extends Control

# NOTE: ONLY WORKS WHEN ATTACHED TO A PARENT NODE

@onready var parent := get_parent()
var property_list: Array[StringName] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	if len(property_list) == 0:
		for property in parent.get_property_list():
			property_list.append(property.name)
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var text := ""
	for property in property_list:
		text += "%s = %s\n" % [property, parent.get(property)]
	
	$Label.text = text
