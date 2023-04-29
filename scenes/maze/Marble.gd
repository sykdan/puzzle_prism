extends RigidBody3D

signal haptic(diff)

var last_vel = 0

func _physics_process(delta):
	var vel = linear_velocity.length()
	var diff = abs(last_vel - vel)
	
	last_vel = vel
	if diff > 1:
		emit_signal("haptic", diff)
