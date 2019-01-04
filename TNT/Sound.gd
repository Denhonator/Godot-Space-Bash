extends AudioStreamPlayer3D

func _on_Sound_finished():
	queue_free()
