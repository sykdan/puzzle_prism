extends RigidBody3D

## Signals that controller vibration should occur.
signal haptic(diff)

var last_vel: float = 0

func _physics_process(_d):
	var vel: float = linear_velocity.length()
	var diff: float = abs(last_vel - vel)
	
	last_vel = vel
	if diff > 1:
		emit_signal("haptic", diff)
