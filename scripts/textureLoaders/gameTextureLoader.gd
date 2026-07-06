@abstract
extends RefCounted
class_name GameTextureLoader

@abstract func current(params:Array=[]) -> Texture2D

func rangei(number:int) -> Array[int]:
	var array:Array[int] = []
	array.assign(range(number))
	return array
