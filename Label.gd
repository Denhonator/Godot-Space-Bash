extends Label

var main

func _ready():
	main = get_node("/root/Main")

func _process(delta):
	text = String(main.minutes).pad_zeros(2)+":"+String(int(main.seconds)).pad_zeros(2)
