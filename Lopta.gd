extends CharacterBody3D

const CUTOFF = 15
const CUTOFF_sqrt = CUTOFF ** 2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= 15.0 * delta

	move_and_slide()
