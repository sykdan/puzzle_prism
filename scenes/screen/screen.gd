extends Node3D

@export var viewport_size: Vector2i
@export var screen_size: Vector2

func _ready():
	$Viewport.size = viewport_size
	$Screen.mesh.size = screen_size
	$ScreenArea/Shape.shape.size.x = screen_size.x
	$ScreenArea/Shape.shape.size.y = screen_size.y
	$Screen.mesh.material.albedo_texture.viewport_path = "./Viewport"
