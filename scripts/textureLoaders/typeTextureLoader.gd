@abstract
extends GameTextureLoader
class_name TypeTextureLoader

var frames:int
var textures:Dictionary[int,GoldIndexTextureLoader] = {}

@abstract func types() -> Array[int]
@abstract func typeNames() -> Array[String]

# replaces $t with typename
func _init(path:String, capitalised:bool=false, _frames:int=1) -> void:
	frames = _frames
	for i in len(types()):
		textures[types()[i]] = (GoldIndexTextureLoader.new(path.replace("$t", typeNames()[i] if capitalised else typeNames()[i].to_lower()),frames))

# param texturetype:TYPE
func current(params:Array=[]) -> Texture2D: return textures[params.pop_front()].current()
