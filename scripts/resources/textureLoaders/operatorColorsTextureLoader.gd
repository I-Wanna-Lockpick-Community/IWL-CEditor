extends ColorsTextureLoader
class_name OperatorColorsTextureLoader

func initLoader(path:String,frames:int,params:Dictionary) -> OperatorTextureLoader:
	return OperatorTextureLoader.new(path,params.capitalised,frames)

static func colorFrames(color:Game.COLOR) -> int:
	match color:
		Game.COLOR.COSMIC: return 1
		_: return super(color)
