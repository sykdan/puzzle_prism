extends Node

signal play(difficulty, params)
signal at_screen(screen)

var difficulty = null
var finish_game_time_taken = null

func _ready():
	back_to_main()
	
func fmt_time(time: int):
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
	play.emit(difficulty, params)
	switch_to(null)

func finish_game(time_took):
	switch_to(^"Results")
	$Results/NewRecord.hide()
	$Results/Continue.hide()
	$Results/Time.text = fmt_time(time_took)
	if SaveFile.will_highscore(time_took, difficulty):
		$Results/NewRecord.show()
	else:
		$Results/Continue.show()
	finish_game_time_taken = time_took

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
