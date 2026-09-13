extends SceneTree
func _init():call_deferred("check")
func sample(id: String,score: int,combo: int=3) -> Dictionary:
	return {"id":id,"score":score,"kills":10,"time":30,"best_combo":combo,"peak_multiplier":2,"damage_dealt":100,"damage_taken":100,"date":"2026-09-13","area":1,"outcome":"lost"}
func check():
	var path="user://records-test-%d.json"%Time.get_ticks_usec()
	var records=CairnRunRecords.new(path)
	var first=records.finish(sample("first",100))
	assert(first.first and first.new_stats.is_empty() and first.rank==1)
	assert(records.save_error==OK)
	assert(records.finish(sample("first",100))==first and records.board().runs.size()==1)
	var second=records.finish(sample("second",200,9))
	assert(second.previous_best==100 and "score" in second.new_stats and "best_combo" in second.new_stats)
	var tied=records.finish(sample("tie",200,9))
	assert(not "score" in tied.new_stats and tied.rank==2)
	for i in 12:records.finish(sample("run-%d"%i,300+i))
	var low=records.finish(sample("low",1,90))
	assert(low.rank==0 and "best_combo" in low.new_stats and records.board().runs.size()==10)
	assert(records.board().bests.best_combo==90)
	assert(not "best_combo" in records.finish(sample("another",2,30)).new_stats)
	var loaded=CairnRunRecords.new(path)
	assert(loaded.board().runs.size()==10 and loaded.board().bests.best_combo==90)
	assert(loaded.board("future-rules").runs.is_empty())
	# Corrupt primary must recover the previous complete backup.
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string("interrupted")
	file.close()
	assert(CairnRunRecords.new(path).board().runs.size()==10)
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
	assert(CairnRunRecords.number(128450)=="128,450" and CairnRunRecords.duration(768)=="12:48")
	print("CAIRN_RECORDS_OK: persistence, backup recovery, ranking, ties, independent bests and deduplication")
	quit()
