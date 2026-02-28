extends GameTextureLoader
class_name ColorsTextureLoader
# recursive

# the number of frames for each color
static func colorFrames(color:Game.COLOR) -> int:
	match color:
		Game.COLOR.MASTER, Game.COLOR.PURE, Game.COLOR.QUICKSILVER: return 4
		Game.COLOR.DYNAMITE: return 12
		_: return 1

var textures:Dictionary[Game.COLOR,GameTextureLoader] = {} # dictionary[color,textureloader]

# initialise the subloader
func initLoader(path:String,frames:int,_params:Dictionary) -> GameTextureLoader:
	return GoldIndexTextureLoader.new(path, frames)

# replaces $c in path with color name, and if there are more than 1 frames, puts the frame index before the .
func _init(path:String,colorSet:Array[Game.COLOR], useIndices:bool=true, capitalised:bool=false, params:Dictionary={}) -> void:
	for color in colorSet:
		var colorName:String = Game.COLOR_NAMES[color] if capitalised else Game.COLOR_NAMES[color].to_lower()
		if useIndices: textures[color] = initLoader(path.replace("$c",colorName),colorFrames(color),params)
		else: textures[color] = initLoader(path.replace("$c",colorName),1,params)

# param: color:Game.COLOR
func current(params:Array=[]) -> Texture2D: return textures[params.pop_front()].current(params)
