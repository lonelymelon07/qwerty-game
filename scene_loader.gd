extends Node

var load_progress : Array[float]
var load_status : int
var target_path : String

func load_scene(path: String):
	target_path = path
	ResourceLoader.load_threaded_request(path)
	

func _process(_delta):
	if target_path:
		load_status = ResourceLoader.load_threaded_get_status(target_path, load_progress)
		print(load_progress[0])
		
		match load_status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				print(load_progress[0])
			ResourceLoader.THREAD_LOAD_LOADED:
				get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(target_path))
				target_path = ""
			ResourceLoader.THREAD_LOAD_FAILED:
				print("Error in load of %s" % target_path)
	
