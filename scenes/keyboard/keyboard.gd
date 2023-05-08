extends ColorRect

signal enter

@export var target: LineEdit

func _ready():
	for letter in $Letters.get_children():
		if letter is Button:
			letter.pressed.connect(handleKeyPress.bind(letter.text))
			
	$Controls/Space.pressed.connect(handleKeyPress.bind(" "))
	$Controls/Backspace.pressed.connect(handleBackSpace)
	$Controls/OK.pressed.connect(emit_signal.bind(&"enter"))

func handleKeyPress(key):
	target.text += key

func handleBackSpace():
	target.text = target.text.left(-1)
