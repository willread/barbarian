extends SceneTree
# Opt-in graphical benchmark; never part of headless correctness tests.
var game
var viewport: SubViewport
var results=[]
var stress="--stress" in OS.get_cmdline_user_args()
var focus="--focus" in OS.get_cmdline_user_args()
func _init():call_deferred("run")
func summary(values: Array) -> Dictionary:
	values.sort()
	var total=0.0
	for value in values:total+=value
	return {"mean":total/maxi(1,values.size()),"p50":values[int(values.size()*.5)],"p95":values[int(values.size()*.95)],"p99":values[mini(values.size()-1,int(values.size()*.99))],"max":values[-1]}
func run():
	if "--asset-probe" in OS.get_cmdline_user_args():
		var effect=load("res://scripts/clinker_visual.gd")
		var held_texture
		var probes=[]
		for retained in [false,true]:
			if retained:held_texture=load("res://art/ember-core-v1.png")
			var values=[]
			for i in 12:
				var begin=Time.get_ticks_usec()
				var bomb=effect.new()
				values.append((Time.get_ticks_usec()-begin)/1000.0)
				bomb.free()
				await process_frame
			probes.append({"retained_texture":retained,"constructor_ms":summary(values)})
		print("BENCH_ASSET_PROBE ",JSON.stringify(probes))
		quit();return
	Engine.max_fps=0
	OS.low_processor_usage_mode=false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	viewport=SubViewport.new()
	viewport.size=Vector2i(1920,1080)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var display=TextureRect.new()
	display.texture=viewport.get_texture()
	display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	display.size=Vector2(960,540)
	root.add_child(display)
	var loaded=Time.get_ticks_msec()
	game=load("res://main.tscn").instantiate()
	viewport.add_child(game)
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	print("BENCH_LOAD_MS ",Time.get_ticks_msec()-loaded)
	game.difficulty="hard"
	game.start_game()
	game.telemetry.network_enabled=false
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(),true)
	for resolution in [Vector2i(1920,1080),Vector2i(3840,2160)]:
		viewport.size=resolution
		viewport.canvas_transform=Transform2D(0,Vector2.ONE*float(resolution.x)/1440.0,0,Vector2.ZERO)
		for episode in [1,2,3]:
			game.current_episode=episode
			for area in [1,2,3,4]:
				if focus and (episode!=3 or area!=4 or resolution.x!=1920):continue
				if stress and not [episode,area] in [[1,3],[2,2],[3,4]]:continue
				seed(12345+episode*10+area)
				game.wave=(area-1)*3+1
				game.spawn_wave()
				game.pending_enemies.clear()
				game.enemies.clear()
				for i in 4:
					var enemy=game.make_actor(400+i*210,650+(i%2)*60,100000)
					enemy.kind=["legion","archer","shield","bone"][i] if episode==1 else ["witch","marauder","legion","champion"][i] if episode==2 else ["bearer","bearer","legion","saint" if area==4 else "champion"][i]
					enemy.boss=enemy.kind=="saint"
					enemy.phaseTwo=enemy.boss
					game.enemies.append(enemy)
				game.hero.x=720;game.hero.y=690
				game.hero.hp=100000;game.hero.max=100000
				game.stage_walk="";game.transition=-1;game.phase="playing"
				game.menu.visible=false
				var wall=[];var gpu=[];var cpu=[];var update=[]
				var start=Time.get_ticks_usec()
				var previous=start
				var burst=-1
				var peak_explosions=0
				var spikes=[]
				var focus_recoveries=0
				print("BENCH_CASE ",episode,"/",area," ",resolution)
				while Time.get_ticks_usec()-start<(23000000 if stress else 7000000):
					var now=Time.get_ticks_usec()
					var elapsed=(now-start)/1000000.0
					var delta=(now-previous)/1000000.0
					previous=now
					# A background benchmark must not inherit the game's focus-loss pause.
					if game.phase=="paused":
						focus_recoveries+=1
						game.phase="playing"
					game.pause_cover=0.0
					game.menu.visible=false
					assert(game.phase=="playing","Benchmark must measure active gameplay")
					game.hero.hp=100000
					if stress and episode==3 and int(elapsed/3)>burst:
						burst=int(elapsed/3)
						for i in 3:
							var blast=load("res://scripts/clinker_explosion.gd").new()
							blast.position=Vector2(600+i*130,690)
							blast.z_index=1800
							game.arena_clip.add_child(blast)
							game.episode_combat.explosions.append(blast)
						var boss=game.enemies[-1]
						boss.attack={};boss.x=1150;boss.y=690;boss.dir=-1
						game.m.begin(boss,"furnaceBlast")
						boss.attack.age=boss.attack.from
					peak_explosions=maxi(peak_explosions,game.episode_combat.explosions.size())
					var before=Time.get_ticks_usec()
					var new_bombs=game.episode_combat.hazards.filter(func(h):return h.kind=="clinker" and not h.has("bomb_view")).size()
					game._process(minf(delta,.05))
					var cost=(Time.get_ticks_usec()-before)/1000.0
					if cost>10:spikes.append({"elapsed":elapsed,"update_ms":cost,"new_bombs_before_update":new_bombs,"bombs_after_update":game.episode_combat.bomb_views.size()})
					await process_frame
					if elapsed>=(3 if stress else 2):
						wall.append((Time.get_ticks_usec()-now)/1000.0)
						update.append(cost)
						gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport.get_viewport_rid()))
						cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport.get_viewport_rid()))
				var result={"resolution":str(resolution),"episode":episode,"area":area,"samples":wall.size(),"frame_ms":summary(wall),"gpu_ms":summary(gpu),"render_cpu_ms":summary(cpu),"update_ms":summary(update),"texture_mib":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
				results.append(result)
				result["peak_explosions"]=peak_explosions
				result["update_spikes"]=spikes
				result["focus_recoveries"]=focus_recoveries
				print("BENCH_RESULT ",JSON.stringify(result))
				if area==4:viewport.get_texture().get_image().save_png("E:/Cairn-build-tools/bench-e%d-%d.png"%[episode,resolution.x])
	var file=FileAccess.open("E:/Cairn-build-tools/performance-%s.json"%("focus" if focus else "stress" if stress else "scenes"),FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"));file.close()
	quit()
