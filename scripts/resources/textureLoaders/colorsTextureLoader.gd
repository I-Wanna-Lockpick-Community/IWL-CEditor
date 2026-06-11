extends GameTextureLoader
class_name ColorsTextureLoader
# recursive

var textures:Dictionary[C.olors,GameTextureLoader] = {} # dictionary[color,textureloader]

## initialise the subloader
func initLoader(path:String,frames:int,_params:Dictionary) -> GameTextureLoader:
	return GoldIndexTextureLoader.new(path, frames)

func colorSelect(color:C.ColorDef) -> bool: return color.doorTexture
func colorFrames(color:C.ColorDef) -> int: return color.doorTextureFrames

## replaces $c in path with color name, and if there are more than 1 frames, puts the frame index before the .
func _init(path:String, useIndices:bool=true, capitalised:bool=false, params:Dictionary={}) -> void:
	for color in Colors.DEFINITIONS:
		if colorSelect(color):
			var colorName:String = color.name if capitalised else color.name.to_lower()
			if useIndices: textures[color.id] = initLoader(path.replace("$c",colorName),colorFrames(color),params)
			else: textures[color.id] = initLoader(path.replace("$c",colorName),1,params)

## param: color:
func current(params:Array=[]) -> Texture2D: return textures[params.pop_front()].current(params)
