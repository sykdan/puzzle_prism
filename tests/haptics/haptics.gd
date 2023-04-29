extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().use_xr = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$XROrigin3D/XRController3D.trigger_haptic_pulse("haptic", $Control/_1.value, $Control/_2.value, 1, 0)
