extends Node

signal play(difficulty, params)
signal at_screen(screen)

var difficulty = null
var finish_game_time_taken = null

func _ready():
	back_to_main()
	for lang in $Settings/Config/Languages.get_children():
		if lang is Button:
			lang.pressed.connect(set_lang.bind(lang.name))

func _process(_d):
	if $Settings.visible:
		$Settings/FPS.text = str(Engine.get_frames_per_second()) + " fps"

func fmt_time(time: int):
	@warning_ignore("integer_division")
	return "%02d:%02d" % [time / 60, time % 60]

func switch_to(screen_type):
	for c in get_children():
		if c is Control:
			c.hide()
	if screen_type:
		get_node(screen_type).show()
	at_screen.emit(screen_type)

func difficulty_selected(diff: StringName):
	difficulty = diff
	$DifficultyDetail/Records.show()
	$DifficultyDetail/Config.hide()
	
	if difficulty == &"easy":
		$DifficultyDetail/Type.text = tr("D_EASY")
		setup_leaderboard_items(SaveFile.easy)
	if difficulty == &"medium":
		$DifficultyDetail/Type.text = tr("D_MEDIUM")
		setup_leaderboard_items(SaveFile.medium)
	if difficulty == &"hard":
		$DifficultyDetail/Type.text = tr("D_HARD")
		setup_leaderboard_items(SaveFile.hard)
	if difficulty == &"custom":
		$DifficultyDetail/Records.hide()
		$DifficultyDetail/Config.show()
		$DifficultyDetail/Type.text = tr("D_CUSTOM")
	
	switch_to(^"DifficultyDetail")

func setup_leaderboard_items(items: Array):
	var r = $DifficultyDetail/Records
	
	for c in r.get_children():
		if c is Label: continue
		c.get_node("RecordBox/Name").text = ""
		c.get_node("RecordBox/Time").text = ""
	
	var idx = 1
	for score in items:
		var c = r.get_child(idx)
		c.get_node("RecordBox/Name").text = score.name
		var time = int(score.time)
		c.get_node("RecordBox/Time").text = fmt_time(score.time)
		idx += 1

func _on_play_pressed():
	var params = null
	if difficulty == &"custom":
		params = Vector3i(
			$DifficultyDetail/Config/Height/Value.value,
			$DifficultyDetail/Config/Width/Value.value,
			$DifficultyDetail/Config/Levels/Value.value
		)
	if SaveFile.first_run:
		switch_to("Controls")
		$Controls/Onboarding_Confirm.show()
		$Controls/Back.hide()
		await $Controls/Onboarding_Confirm.pressed
		$Controls/Onboarding_Confirm.hide()
		$Controls/Back.show()
		SaveFile.first_run = false
		SaveFile.store_save()
	switch_to(null)
	play.emit(difficulty, params)

func finish_game(time_taken):
	switch_to(^"Results")
	$Results/NewRecord.hide()
	$Results/Continue.hide()
	$Results/Time.text = fmt_time(time_taken)
	if SaveFile.will_highscore(time_taken, difficulty):
		$Results/NewRecord.show()
	else:
		$Results/Continue.show()
	finish_game_time_taken = time_taken

func back_to_main():
	switch_to(^"MainMenu")

func _on_name_enter():
	var player = $SubmitScore/NameEnter.text
	if not len(player):
		return
	
	SaveFile.push_score(player, finish_game_time_taken, difficulty)
	finish_game_time_taken = null
	back_to_main()

func scoreboard_submit():
	$SubmitScore/NameEnter.text = ""
	switch_to(^"SubmitScore")
	
func custom_edit_button_diff(property, delta):
	$DifficultyDetail/Config.get_node(property).get_node("Value").value += delta


func reset_first_run():
	SaveFile.first_run = true
	SaveFile.store_save()


func reset_scores():
	SaveFile.easy = []
	SaveFile.medium = []
	SaveFile.hard = []
	SaveFile.store_save()

func set_lang(lang):
	SaveFile.locale = lang
	SaveFile.store_save()
