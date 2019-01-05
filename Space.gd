extends Spatial

var seconds = 0
var minutes = 0
var runTimer = true
var menu
var players = {"Player1":null,"Player2":null}

func _ready():
	if not get_tree().has_meta("connected"):
		get_tree().set_meta("connected",0)
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	menu = find_node("Menu")
	players["Player1"] = find_node("Players").find_node("Characters").find_node("Player1")
	players["Player2"] = find_node("Players").find_node("Characters").find_node("Player2")
	find_node("Menu").find_node("Disconnect").visible = get_tree().network_peer!=null
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
	menu.find_node("Disconnect").visible = true
	PopupText("Connected!")
	print("Connected")

func _player_disconnected(id):
	Disconnect()

func _connected_ok():
	menu.find_node("Disconnect").visible = true
	PopupText("Connected!")
	print("Connected")

func _server_disconnected():
	Disconnect()

func _connected_fail():
	print("Failed to connect")
	Disconnect()
	
func PopupText(t):
	menu.find_node("Connected").text = t

func _on_Join_pressed():
	if not get_tree().network_peer:
		var peer = NetworkedMultiplayerENet.new()
		peer.create_client(find_node("Menu").find_node("IP").text, int(find_node("Menu").find_node("PORT").text))
		get_tree().set_network_peer(peer)
		players["Player1"].local = false
		players["Player2"].controls = "Player1"
		get_tree().set_meta("connected",2)
	
func _on_Host_pressed():
	if not get_tree().network_peer:
		var peer = NetworkedMultiplayerENet.new()
		peer.create_server(int(find_node("Menu").find_node("PORT").text), 2)
		get_tree().set_network_peer(peer)
		menu.find_node("Disconnect").visible = true
		players["Player2"].local = false
		get_tree().set_meta("connected",1)

func _on_Disconnect_pressed():
	if get_tree().network_peer:
		rpc("Disconnect")

sync func Disconnect():
	get_tree().set_meta("connected",0)
	menu.visible = true
	get_tree().paused = true
	menu.find_node("Disconnect").visible = false
	PopupText("Disconnected")
	players["Player1"].local = true
	players["Player2"].local = true
	players["Player2"].controls = "Player2"
	get_tree().set_network_peer(null)
	print("Disconnected")
	