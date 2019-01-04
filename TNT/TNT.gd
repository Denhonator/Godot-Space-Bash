extends KinematicBody

var player = null
var hasDestroyed = false
var timer = 4
var thrown = false
var mesh
var materials = []
var expl
var downray
var explosion
var sound
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

func PickedUp(node):
	if not nitro:
		player = node
		timer = min(2.99, timer)
		return true
	return false
	
func Throw():
	velocity = (player.get_global_transform().basis.y*5+Vector3(0,4,0))
	player = null
	thrown = true

func Explode():
	var newExplosion = explosion.instance()
	newExplosion.transform.origin = transform.origin
	newExplosion.emitting = true
	get_parent().add_child(newExplosion)
	if player:
		player.carrying = null
	for body in expl.get_overlapping_bodies():
		if body.has_method("GetHit") and body!=self:
			body.GetHit(((body.transform.origin-transform.origin)*Vector3(1,0,1)).normalized(),Vector3(0,0,0))
	if downray.is_colliding():
		DestroyTile(downray.get_collider())
	remove_child(sound)
	get_parent().add_child(sound)
	sound.seek(3.1)
	queue_free()
	
func GetHit(ex,hit):
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
	if !hasDestroyed and body.get_name().substr(0,4)=="Tile":
		body.queue_free()
		hasDestroyed = true

func _on_body_entered(body):
	if (thrown or (nitro and body.get_name().substr(0,4)!="Tile")) and body!=self:
		DestroyTile(body)
		timer = 0
