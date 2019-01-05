extends Spatial

var seconds = 0
var minutes = 0
var runTimer = true
var menu
var peer
var players = {"Player1":null,"Player2":null}

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	menu = find_node("Menu")
	players["Player1"] = find_node("Players").find_node("Characters").find_node("Player1")
	players["Player2"] = find_node("Players").find_node("Characters").find_node("Player2")
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			players["Player2"].local = false
		else:
			players["Player1"].local = false
	get_tree().paused = true

func _process(delta):
	if runTimer and not get_tree().paused:
		seconds+=delta
		if seconds>=60:
			seconds-=60
			minutes+=1	
	if Input.is_action_just_pressed("ui_cancel"):
		Pause()
		if get_tree().has_network_peer():
			rpc("Pause")
		
remote func Pause():
	menu.visible = !menu.visible
	get_tree().paused = menu.visible
	
remote func Restart():
	get_tree().paused = false
	get_tree().change_scene("res://Space.tscn")
	
func _on_Restart_pressed():
	Restart()
	if get_tree().has_network_peer():
		rpc("Restart")

func _on_Quit_pressed():
	get_tree().quit()
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		AudioServer.set_bus_mute(0,false)
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		AudioServer.set_bus_mute(0,true)
	
func _player_connected(id):
	print("Connected")

func _player_disconnected(id):
	players["Player1"].local = true
	players["Player2"].local = true
	print("Disconnected")

func _connected_ok():
	print("Connected")

func _server_disconnected():
	players["Player1"].local = true
	players["Player2"].local = true
	print("Disconnected")

func _connected_fail():
	players["Player1"].local = true
	players["Player2"].local = true
	print("Failed to connect")

func _on_Join_pressed():
	peer = NetworkedMultiplayerENet.new()
	peer.create_client("127.0.0.1", 7777)
	get_tree().set_network_peer(peer)
	players["Player1"].local = false
	
func _on_Host_pressed():
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(7777, 2)
	get_tree().set_network_peer(peer)
	players["Player2"].local = false
