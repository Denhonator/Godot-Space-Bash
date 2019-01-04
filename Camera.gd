extends Camera

var players
var smooth = 0.05

func _ready():
	players = get_parent().find_node("Players")

func _process(delta):
	var average = Vector3(0,0,0)
	var prev = null
	var distance = 0
	for p in players.get_children():
		average+=p.transform.origin
		if prev:
			distance = max(distance,(p.transform.origin-prev).length_squared())
		prev = p.transform.origin
	distance=(distance-130)/15
	fov = lerp(fov,80+distance,smooth)
	if players.get_child_count():
		average /= players.get_child_count()
	average+=Vector3(9,6.5,0)
	transform.origin = Vector3(lerp(transform.origin.x,average.x,smooth),lerp(transform.origin.y,average.y,smooth),lerp(transform.origin.z,average.z,smooth))
