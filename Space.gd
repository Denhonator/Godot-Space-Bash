extends Spatial

var seconds = 0
var minutes = 0
var runTimer = true
var menu

func _ready():
	menu = find_node("Menu")

func _process(delta):
	if runTimer and not get_tree().paused:
		seconds+=delta
		if seconds>=60:
			seconds-=60
			minutes+=1
	if Input.is_action_just_pressed("ui_cancel"):
		menu.visible = !menu.visible
		get_tree().paused = menu.visible
	
func _on_Restart_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://Space.tscn")


func _on_Quit_pressed():
	get_tree().quit()
