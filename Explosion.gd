extends Node

export(float) var aliveTime

func _process(delta):
	aliveTime-=delta
	if aliveTime<=0:
		queue_free()
	pass
