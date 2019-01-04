extends Spatial

var tiles
var TNT
var nitro
var interval = 6
var timer
var amount = 2
var a 
var newTNT

func _ready():
	a = amount
	timer = interval-2
	tiles = find_node("Floor")
	TNT = preload("res://TNT/TNT.tscn")
	nitro = preload("res://TNT/nitro.tscn")
	pass
	
func SpawnTNT():
	if a==0:
		newTNT = nitro.instance()
	else:
		newTNT = TNT.instance()
	for i in range(10):
		var r = rand_range(0.0,tiles.get_child_count()-0.1)
		if tiles.get_child(r).get_child(2).get_overlapping_bodies().empty():
			var childpos = tiles.get_child(r).transform.origin
			childpos.y=newTNT.transform.origin.y
			newTNT.transform.origin = childpos
			newTNT.scale = Vector3(0,0,0)
			add_child(newTNT)
			if get_tree().has_network_peer():
				rpc("SpawnTNTTo",childpos, a==0)
			return
			
remote func SpawnTNTTo(pos, n):
	if n:
		newTNT = nitro.instance()
	else:
		newTNT = TNT.instance()
	newTNT.transform.origin = pos
	newTNT.scale = Vector3(0,0,0)
	add_child(newTNT)

func _process(delta):
	timer+=delta
	if timer>interval:
		if a>0:
			a-=1
			timer = interval-0.3
		else:
			timer=0
			a = amount
		SpawnTNT()


func _on_TNTButton():
	SpawnTNT()
