# AUTOLOAD

extends Node

signal loaded

var load_status: int = ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
var target_path: String
var load_progress: float:
	get:
		return _load_progress_arr[0]
var _load_progress_arr: Array[float]


func _process(_delta):
	load_status = ResourceLoader.load_threaded_get_status(target_path, _load_progress_arr)
	
	match load_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
		ResourceLoader.THREAD_LOAD_LOADED:
#			get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(target_path))
#			target_path = ""
			loaded.emit(ResourceLoader.load_threaded_get(target_path))
			set_process(false)
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Error loading scene %s" % target_path)
			set_process(false)


func load_scene(path: String):
	target_path = path
	set_process(true)
	ResourceLoader.load_threaded_request(path)

