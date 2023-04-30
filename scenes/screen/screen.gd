extends Node3D

func _ready():
	$Screen/ScreenArea/Shape.shape.size.x = $Screen.mesh.size.x
	$Screen/ScreenArea/Shape.shape.size.y = $Screen.mesh.size.x
	$Screen.mesh.material.albedo_texture.viewport_path = "./Viewport"
