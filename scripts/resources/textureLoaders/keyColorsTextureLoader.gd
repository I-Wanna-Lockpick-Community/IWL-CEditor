extends ColorsTextureLoader
class_name KeyColorsTextureLoader

func initLoader(path:String,frames:int,params:Dictionary) -> KeyTextureLoader:
	return KeyTextureLoader.new(path,params.capitalised,frames)

static func colorFrames(color:Game.COLOR) -> int:
	match color:
		Game.COLOR.COSMIC: return 1
		_: return super(color)
