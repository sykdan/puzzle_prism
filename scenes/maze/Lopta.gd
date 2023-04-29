extends CharacterBody3D

var paused = false

signal hit_vibrate(strength)

var down = Vector3.DOWN

func _physics_process(delta):
	if paused: return
	
	var v = velocity.length()
	var movement = down * 40 * delta 
	velocity += movement
	print(move_and_slide())
	var diff = max(0, v - velocity.length())
	
	if diff > 0.4:
		emit_signal("hit_vibrate",diff)
