extends KinematicBody

var player = null
var timer = 4
var thrown = false
var mesh
var materials = []
var expl
var downray
var explosion
var sound
var DestroyPath = null
var velocity = Vector3(0,0,0)

export(bool) var nitro

func _ready():
	mesh = find_node("MeshInstance")
	materials.append(load("res://TNT/TNT1.tres"))
	materials.append(load("res://TNT/TNT2.tres"))
	materials.append(load("res://TNT/TNT3.tres"))
	explosion = load("res://Explosion/Explosion.tscn")
	expl = find_node("Explosion")
	downray = find_node("RayCast")
	sound = find_node("Sound")

func _process(delta):
	if scale.x<1:
		scale += Vector3(0.1,0.1,0.1)
	if player:
		transform.origin = player.transform.origin+player.get_global_transform().basis.y*1.3+Vector3(0,1,0)
	if timer < 3:
		if not sound.playing:
			sound.play(3-timer)
		if timer<=0:
			Explode()
		else:
			mesh.material_override = materials[int(timer)]
			timer-=delta
	
	velocity.y = -0.1 if is_on_floor() or player else velocity.y-0.2
	velocity.x = 0.96*velocity.x if is_on_floor() else velocity.x
	velocity.z = 0.96*velocity.z if is_on_floor() else velocity.z
	
	if velocity.y<-5:
		thrown = true
		
	move_and_slide(velocity, Vector3(0,1,0))
	
	if get_tree().get_meta("connected")==1:
		rpc_unreliable("Sync",timer,velocity,translation)
		
remote func Sync(t,v,p):
	timer = t
	velocity = v
	translation.x = lerp(translation.x,p.x,0.2)
	translation.y = lerp(translation.y,p.y,0.2)
	translation.z = lerp(translation.z,p.z,0.2)
	
remote func SetPlayer(name):
	player = get_tree().root.get_child(0).players[name]
	timer = min(2.99, timer)

func PickedUp(node):
	if not nitro:
		player = node
		if get_tree().has_network_peer():
			rpc("SetPlayer", player.get_name())
		timer = min(2.99, timer)
		return true
	return false
	
remote func Throw(dir):
	if player:
		velocity = dir
		player = null
		thrown = true
		if get_tree().has_network_peer():
			rpc("Throw",dir)

func Explode():
	if get_tree().get_meta("connected")<2:
		for body in expl.get_overlapping_bodies():
			if body.has_method("GetHit") and body!=self:
				body.GetHit(((body.transform.origin-transform.origin)*Vector3(1,0,1)).normalized(),Vector3(0,0,0))
		if not DestroyPath and downray.is_colliding():
			DestroyPath = DestroyTile(downray.get_collider())
		RExplode(DestroyPath)
		if get_tree().has_network_peer():
			rpc("RExplode",DestroyPath)
		
remote func RExplode(path):
	var newExplosion = explosion.instance()
	newExplosion.transform.origin = transform.origin
	newExplosion.emitting = true
	get_parent().add_child(newExplosion)
	if player:
		player.carrying = null
	remove_child(sound)
	get_parent().add_child(sound)
	sound.seek(3.1)
	if path:
		var body = get_node(path)
		if body:
			get_node(path).queue_free()
	queue_free()
	
func GetHit(ex,hit):
	RGetHit(ex,hit)
	if get_tree().has_network_peer():
		rpc("RGetHit",ex,hit)
		
remote func RGetHit(ex,hit):
	if nitro:
		timer = 0
		return
	if ex.length_squared():
		timer = 0.25
	elif hit.y<0:
		timer = min(2.99,timer)
	else:
		velocity += hit*7
		timer = min(2.99,timer)
	
func DestroyTile(body):
	if body.get_name().substr(0,4)=="Tile":
		return body.get_path()

func _on_body_entered(body):
	if (thrown or (nitro and body.get_name().substr(0,4)!="Tile") or (body.has_method("Die") and velocity.length_squared() > 5 and (body.vel-velocity).length_squared()>5)) and body!=self:
		if body.get_name().substr(0,4)=="Tile":
			DestroyPath = body.get_path()
		timer = 0
