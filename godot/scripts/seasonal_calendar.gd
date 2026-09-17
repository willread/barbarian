extends RefCounted
# Gregorian Easter Sunday, calculated each year rather than a fixed April date.
static func easter_date(year: int) -> String:
	@warning_ignore("integer_division")
	var century=year/100
	var a=year%19
	var d=century/4
	var f=(century+8)/25
	var g=(century-f+1)/3
	var h=(19*a+century-d-g+15)%30
	var c=year%100
	var l=(32+2*(century%4)+2*(c/4)-h-c%4)%7
	var m=(a+11*h+22*l)/451
	var value=h+l-7*m+114
	return "%04d-%02d-%02d"%[year,value/31,value%31+1]
static func is_easter(date: String) -> bool:
	return date.length()==10 and date==easter_date(int(date.left(4)))
