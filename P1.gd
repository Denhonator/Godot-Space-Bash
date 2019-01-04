extends KinematicBody

var vel = Vector3(0,0,0)
var maxms = 4.5
var carryms = 2.5
var ms
var turnrate = 0.25
var onGround = false
var carrying = null
var inFront = null
var stun = 0
var health = 100
var hpbar
var ray
var attack
var audio
var particles
var state = {"throw":0,"pickup":0,"attack":0}

func _ready():
	ray = find_node("RayCast")
	attack = find_node("Attack")
	audio = find_node("Audio")
	particles = find_node("Particles")
	hpbar = get_parent().get_parent().find_node("UI").find_node(get_name()+"Health")
	ms = maxms

func _process(delta):
	if transform.origin.y < -3 or health<=0:
		Die()
	MovementAndPhysics(delta)
	if state["attack"]<=0 and onGround:
		PickupAndThrow(delta)
	Stomp()
	if not carrying and stun<=0:
		Attack(delta)
	
func Die():
	queue_free()
	
func Attack(delta):
	if state["attack"]<=-0.5 and Input.is_action_just_pressed(get_name()+"attack"):
		state["attack"]=0.5
		audio.play()
		for body in attack.get_overlapping_bodies():
			if body.has_method("GetHit") and body!=self:
				body.GetHit(Vector3(0,0,0), Vector3(body.transform.origin.x-transform.origin.x,0,body.transform.origin.z-transform.origin.z).normalized())
	particles.emitting = state["attack"] > 0.4
	if state["attack"]>0:
		rotate_y(10)
	if state["attack"]>-0.5:
		state["attack"]-=delta
		
func Stomp():
	if onGround and ray.is_colliding():
		var col = ray.get_collider()
		if col.has_method("Explode"):
			col.GetHit(Vector3(0,0,0), Vector3(0,-1,0))
			return
		col = col.get_parent()
		if col.has_method("Explode"):
			col.GetHit(Vector3(0,0,0), Vector3(0,-1,0))
			return
		else:
			ray.add_exception(col)
	
func PickupAndThrow(delta):
	if Input.is_action_just_pressed(get_name()+"grab"):
		if carrying:
			state["throw"] = 0.3
			ms = 0
		elif inFront:
			if inFront.PickedUp(self):
				carrying = inFront
				stun = 0.3
				ms = carryms
				vel = Vector3(0,0,0)
				state["pickup"] = 0.3
	if state["pickup"]>0:
		state["pickup"]-=delta
	if state["throw"]>0:
		state["throw"]-=delta
		if state["throw"]<=0.1 and carrying:
			carrying.Throw()
			carrying = null
		elif state["throw"]<=0:
			ms = maxms
	
func MovementAndPhysics(delta):
	var inDir = Vector2(0,0)
	if Input.is_action_pressed(get_name()+"left"):
		inDir.x = 1
	elif Input.is_action_pressed(get_name()+"right"):
		inDir.x = -1
	if Input.is_action_pressed(get_name()+"up"):
		inDir.y = -1
	elif Input.is_action_pressed(get_name()+"down"):
		inDir.y = 1
	inDir = inDir.normalized()
	
	if stun<=0:
		vel.x = inDir.y*ms
		vel.z = inDir.x*ms
	
	if stun>0:
		stun-=delta
		vel.x*=0.9
		vel.z*=0.9
	
	if stun<=0 and state["attack"]<=0 and inDir.length_squared():
		var angle = inDir.angle()-rotation.y
		if(angle>PI):
			angle-=2*PI
		if(angle<-PI):
			angle+=2*PI
		rotate_y(clamp(angle,-turnrate,turnrate))
	
	onGround = is_on_floor()
	
	if not onGround:
		vel.y -= 0.2
	else:
		if not carrying and Input.is_action_just_pressed(get_name()+"jump"):
			vel.y = 6
		else:
			vel.y = -0.2
	
	move_and_slide(vel, Vector3(0,1,0))

func GetHit(ex,hit):
	if stun<=0:
		if ex.length_squared():
			vel=ex*10
			health-=20
		elif hit.length_squared():
			vel=hit*10
			health-=10
		stun = 1
		state["attack"]=0
		hpbar.value = health

func _on_Area_body_entered(body):
	if body.has_method("PickedUp"):
		inFront = body


func _on_Area_body_exited(body):
	if body==inFront:
		inFront = null


func _on_Attack_body_entered(body):
	if state["attack"]>0 and body!=self and body.has_method("GetHit"):
		body.GetHit(Vector3(0,0,0), Vector3(body.transform.origin.x-transform.origin.x,0,body.transform.origin.z-transform.origin.z).normalized())
