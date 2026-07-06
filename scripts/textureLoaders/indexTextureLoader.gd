extends GameTextureLoader
class_name IndexTextureLoader

var frames:int
var textures:Array[Texture2D] = []

func _init(path:String,_frames:int) -> void:
	frames = _frames
	if frames == 1: textures.append(load(path))
	else: for i in frames: textures.append(load(path.replace(".",str(i)+".")))

func current(params:Array=[]) -> Texture2D: return textures[params.pop_front()]
