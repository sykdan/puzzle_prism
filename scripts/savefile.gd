extends Node

@export var easy = []
@export var medium = []
@export var hard = []

var first_run = true
var locale = "en" :
	set(new_locale):
		TranslationServer.set_locale(new_locale)
		locale = new_locale

var should_save = [&"easy", &"medium", &"hard", &"first_run", &"locale"]

func _ready():
	load_save()

func load_save():
	var file = FileAccess.open("user://puzzleprism_data.dat", FileAccess.READ)
	var e: Error = FileAccess.get_open_error()
	if e != OK:
		locale = "cs" if OS.get_locale_language() == "cs" else "en"
		store_save()
		return
	
	var savedata = file.get_as_text()
	var json: Dictionary = JSON.parse_string(savedata)
	
	if json == null:
		return
	
	for variable in should_save:
		if not json.has(variable):
			set(variable, get(variable))
		else:
			set(variable, json[variable])

func store_save():
	var file = FileAccess.open("user://puzzleprism_data.dat", FileAccess.WRITE)
	var data = {}
	for variable in should_save:
		data[variable] = get(variable)
	file.store_string(JSON.stringify(data))

func push_score(player, time, to_where: StringName):
	var dest: Array = get(to_where)
	dest.append({"name": player, "time": time})
	dest.sort_custom(func(a, b): return a.time < b.time)
	while len(dest) > 5:
		dest.pop_back()
	store_save()

func will_highscore(time, which: StringName):
	if which == &"custom":
		return false
	var dest: Array = get(which)
	return len(dest) < 5 or (dest.back().time < time)
