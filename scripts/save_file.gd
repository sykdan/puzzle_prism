extends Node

@export var scores_easy = []
@export var scores_medium = []
@export var scores_hard = []

var should_save = [&"scores_easy", &"scores_medium", &"scores_hard"]

func _ready():
	load_save()

func load_save():
	var file = FileAccess.open("user://puzzleprism_data.dat", FileAccess.READ)
	var e: Error = FileAccess.get_open_error()
	if e != OK:
		store_save()
		return
	
	var savedata = file.get_as_text()
	var json: Dictionary = JSON.parse_string(savedata)
	
	if json == null:
		return
	
	for variable in should_save:
		if not json.has(variable):
			continue
		set(variable, json[variable])

func store_save():
	var file = FileAccess.open("user://puzzleprism_data.dat", FileAccess.WRITE)
	var data = {}
	for variable in should_save:
		data[variable] = get(variable)
	file.store_string(JSON.stringify(data))

func maybe_push_score(name, time):
	pass
