extends SceneTree
func _init():call_deferred("check")
func check():
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.start_game()
 var console=game.debug_console
 game.change_phase("paused")
 console.toggle()
 assert(not console.visible and not paused,"Cheats must not open on pause menus")
 game.change_phase("title")
 console.toggle()
 assert(not console.visible,"Cheats must not open on title menus")
 game.start_game()
 console.toggle()
 assert(console.letters.size()==3 and console.code.is_empty())
 for letter in console.letters:assert(letter.texture==console.textures["?"],"Opening shows three question marks")
 var slots=console.letters.map(func(letter):return letter.position.x)
 assert(is_equal_approx(slots[1]-slots[0],slots[2]-slots[1]))
 var clock=game.clock
 await create_timer(.1).timeout
 assert(paused and game.clock==clock)
 game.hero.hp=12
 console.accept_letter("E")
 console.accept_letter("M")
 assert(console.code=="EM" and paused and game.hero.hp==12)
 assert(console.letters.size()==3 and console.letters[0].texture==console.textures["E"] and console.letters[1].texture==console.textures["M"] and console.letters[2].texture==console.textures["?"],"Typed letters replace existing slots")
 console.accept_letter("1")
 assert(console.code=="EM")
 if "--console-capture" in OS.get_cmdline_user_args():
  await create_timer(.8).timeout
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("E:/Cairn-build-tools/debug-console.png")
 console.accept_letter("T")
 console.accept_letter("X")
 assert(console.code=="EMT")
 assert(console.letters.map(func(letter):return letter.position.x)==slots,"Different glyph widths must never move any slot")
 await create_timer(1.2).timeout
 assert(game.hero.hp==game.hero.max and not paused and not console.visible)
 assert(console.feedback.stream==console.success_sound,"Successful cheat plays ka-ching")
 console.toggle()
 console.execute("HOH")
 assert(game.candy_override and game.weapon_skin=="candy_cane" and not paused)
 console.toggle()
 console.execute("KFC")
 assert(not game.chicken.is_empty() and not paused)
 for area in range(2,5):
  console.toggle()
  console.execute("FWD")
  assert(game.screen_for_wave(game.wave)==area and not paused)
 console.toggle()
 console.execute("FWD")
 assert(game.wave==10)
 console.toggle()
 console.execute("CEO")
 assert(game.wave==game.encounters.size() and game.enemies[0].boss)
 console.toggle()
 console.accept_letter("Z")
 console.accept_letter("Z")
 console.accept_letter("Z")
 await create_timer(1.2).timeout
 assert(not paused and not console.visible)
 assert(console.feedback.stream==console.failure_sound,"Invalid code plays the failure voice")
 console.feedback.stop()
 console.feedback.stream=null
 console.toggle()
 console.accept_letter("E")
 console.close()
 await create_timer(.7).timeout
 assert(not paused and not console.visible)
 assert(console.feedback.stream==null and not console.feedback.playing,"Cancellation produces no result sound")
 var brute=game.m.make(900,820,660,100)
 brute.variant="brute"
 brute.size=1.18
 game.hero.attack={}
 game.m.begin(game.hero,"spin")
 game.damage(brute,game.hero.attack,game.hero)
 assert(brute.hp==100 and game.hero.attack.is_empty() and game.hero.chargeRebound!=0,"Spin rebounds off brutes without damage")
 var boss=game.enemies[0]
 boss.x=900
 var offscreen=game.m.make(901,-300,660,100)
 game.enemies.append(offscreen)
 var before_kills=game.kills
 var before_hp=game.hero.hp
 game.damage_multiplier=0
 console.toggle()
 console.execute("TNT")
 assert(boss.hp==0 and not boss.down.is_empty(),"TNT kills bosses through defenses")
 assert(offscreen.hp==100 and game.hero.hp==before_hp,"TNT spares offscreen enemies and player")
 assert(game.kills==before_kills+1 and not paused)
 console.toggle()
 console.execute("TNT")
 assert(game.kills==before_kills+1,"TNT cannot kill a corpse twice")
 game.queue_free()
 await process_frame
 print("CAIRN_CONSOLE_OK: three letter drops, automatic commands, freeze/resume, boss, cancel and unknown codes")
 quit()
