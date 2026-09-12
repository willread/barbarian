extends Node2D
const W=320
const H=180
var age=-.5
var sim_time=0.0
var field=PackedFloat32Array()
var next=PackedFloat32Array()
var deposits: Array=[]
var pixels=PackedByteArray()
var image: Image
var texture: ImageTexture
func _ready():
	z_index=2050
	field.resize(W*H)
	next.resize(W*H)
	pixels.resize(W*H*4)
	var bursts=[]
	for i in 5: bursts.append({"at":.06+randf()*.5,"width":.012+randf()*.07})
	for n in 280:
		var burst=bursts.pick_random()
		var arrival=.03+randf()*.62 if randf()<.24 else clamp(burst.at+(randf()+randf()-1)*burst.width,.03,.65)
		deposits.append({"x":randf()*W,"y":randf()*H,"rx":9+randf()*19 if n<72 else 1+randf()*6,"ry":6+randf()*12 if n<72 else 1+randf()*4,"angle":randf()*PI,"phase":randf()*TAU,"lobes":2+randi()%4,"roughness":pow(randf(),1.7),"amount":1.7+randf()*2 if n<72 else .3+randf()*1.1,"at":arrival})
	deposits.sort_custom(func(a,b):return a.at<b.at)
	image=Image.create(W,H,false,Image.FORMAT_RGBA8)
	texture=ImageTexture.create_from_image(image)
func advance(dt: float):
	age=min(3.8,age+dt)
	if age<0: return
	while sim_time+CairnMechanics.STEP<=age:
		simulate()
		sim_time+=CairnMechanics.STEP
	shade()
	queue_redraw()
func simulate():
	while not deposits.is_empty() and deposits[0].at<=sim_time:
		var d=deposits.pop_front()
		var bound=max(d.rx,d.ry)*2.7
		var cs=cos(d.angle)
		var sn=sin(d.angle)
		for y in range(max(0,int(d.y-bound)),min(H,int(d.y+bound))):
			for x in range(max(0,int(d.x-bound)),min(W,int(d.x+bound))):
				var dx=x-d.x
				var dy=y-d.y
				var u=(dx*cs+dy*sn)/d.rx
				var v=(-dx*sn+dy*cs)/d.ry
				var theta=atan2(v,u)
				var contour=1+d.roughness*(.22*sin(theta*d.lobes+d.phase)+.085*sin(theta*(d.lobes+3)-d.phase))
				field[y*W+x]+=d.amount*exp(-(u*u+v*v)/(contour*contour)*2.8)
	var settling=clamp((sim_time-1.8)/2,0,1)
	var rate=1-settling*settling*(3-2*settling)
	next=field.duplicate()
	for y in H:
		for x in W:
			var i=y*W+x
			var v=field[i]
			var mobile=max(0,v-.12)
			if not mobile: continue
			var down=min(mobile*.38,mobile*mobile*.075)*rate
			next[i]-=down
			if y<H-1: next[i+W]+=down
			if x<W-1:
				var flux=clamp((v-field[i+1])*.025,-.08,.08)
				var limited=(min(flux,mobile*.12) if flux>0 else -min(-flux,max(0,field[i+1]-.12)*.12))*rate
				next[i]-=limited
				next[i+1]+=limited
	field=next
func shade():
	for y in H:
		for x in W:
			var i=y*W+x
			var v=field[i]
			var k=i*4
			var coverage=clamp((v-.035)*18,0,1)
			if not coverage:
				pixels[k+3]=0
				continue
			var nx=(field[y*W+max(0,x-1)]-field[y*W+min(W-1,x+1)])*2.2
			var ny=(field[max(0,y-1)*W+x]-field[min(H-1,y+1)*W+x])*2.2
			var inv=1/sqrt(1+nx*nx+ny*ny)
			var diffuse=max(0,(-nx*.4-ny*.5+.7)*inv)
			var highlight=pow(max(0,(-nx*.28-ny*.38+.881)*inv),65)
			pixels[k]=clamp(48+54/(1+v*.6)+diffuse*21+highlight*175,0,255)
			pixels[k+1]=clamp(2+diffuse*5+highlight*139,0,255)
			pixels[k+2]=clamp(7+diffuse*8+highlight*132,0,255)
			pixels[k+3]=coverage*255
	image.set_data(W,H,false,Image.FORMAT_RGBA8,pixels)
	texture.update(image)
func _draw():
	if age<0: return
	var fade=clamp((age-.25)/1.3,0,1)
	draw_rect(Rect2(0,0,1440,1062),Color(.439,.035,.063,fade*fade*(3-2*fade)))
	draw_texture_rect(texture,Rect2(0,0,1440,1062),false)

