# AUTOLOAD
# Here basically to manage all persistent game data

extends Node

var main_menu_data := {
	custom_level_edit_text = "",
	custom_song_edit_text = ""
}

var config := {}


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var config_file = ConfigFile.new()
	var err = config_file.load("res://config.cfg")
	
	if err:
		print("Error loading config file: %s" % err)
	
	for section in config_file.get_sections():
		config[section] = {}
		for key in config_file.get_section_keys(section):
			config[section][key] = config_file.get_value(section, key, null)
			
	print(config)

func _input(event):
	if event.is_action_pressed(&"pause"):
		get_tree().paused = not get_tree().paused
