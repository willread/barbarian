class_name CairnRunRecords
extends RefCounted
# Versioned local records. Personal stat bests survive top-ten eviction.
const RULES="citadel-v1"
const BEST_KEYS=["score","kills","best_combo","peak_multiplier","damage_dealt"]
var path: String
var scopes: Dictionary={}
var save_error=OK
var last_result: Dictionary={}

func _init(save_path: String="user://records.json"):
	path=save_path
	if path.is_empty():return
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate):continue
		var parser=JSON.new()
		if parser.parse(FileAccess.get_file_as_string(candidate))!=OK:continue
		var data=parser.data
		if data is Dictionary and data.get("version",0)==1 and data.get("scopes") is Dictionary:
			scopes=data.scopes
			break

func board(scope: String=RULES) -> Dictionary:
	if not scopes.get(scope) is Dictionary:scopes[scope]={}
	var value: Dictionary=scopes[scope]
	if not value.get("runs") is Array:value.runs=[]
	value.runs=value.runs.filter(func(r):return r is Dictionary and r.get("id") is String and (r.get("score") is float or r.get("score") is int))
	if not value.get("bests") is Dictionary:value.bests={}
	return value

func finish(snapshot: Dictionary,scope: String=RULES) -> Dictionary:
	if last_result.get("id")==snapshot.id:return last_result
	var data=board(scope)
	for run in data.runs:
		if run.id==snapshot.id:return run
	var result=snapshot.duplicate(true)
	result.previous_best=int(data.bests.get("score",0))
	result.first=data.bests.is_empty()
	result.new_stats=[]
	for key in BEST_KEYS:
		var value=float(result.get(key,0))
		if not result.first and value>float(data.bests.get(key,0)):result.new_stats.append(key)
		data.bests[key]=maxf(value,float(data.bests.get(key,0)))
	# Insert after equal scores so ties preserve their existing order.
	var rank=0
	while rank<data.runs.size() and float(data.runs[rank].score)>=float(result.score):rank+=1
	result.rank=rank+1 if rank<10 else 0
	data.runs.insert(rank,result.duplicate(true))
	if data.runs.size()>10:data.runs.resize(10)
	last_result=result
	save_error=persist()
	return result

func persist() -> Error:
	if path.is_empty():return OK
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version":1,"scopes":scopes}))
	file.flush()
	var error=file.get_error()
	file.close()
	if error!=OK:return error
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak"):
			error=DirAccess.remove_absolute(path+".bak")
			if error!=OK:return error
		error=DirAccess.rename_absolute(path,path+".bak")
		if error!=OK:return error
	return DirAccess.rename_absolute(path+".tmp",path)

static func number(value: float) -> String:
	var digits=str(int(value))
	var result=""
	for i in digits.length():
		if i>0 and (digits.length()-i)%3==0:result+=","
		result+=digits[i]
	return result

static func duration(seconds: float) -> String:
	return "%02d:%02d"%[int(seconds)/60,int(seconds)%60]
