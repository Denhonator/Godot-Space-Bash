extends Spatial

var seconds = 0
var minutes = 0
var runTimer = true

func _process(delta):
	if runTimer:
		seconds+=delta
		if seconds>=60:
			seconds-=60
			minutes+=1
	
