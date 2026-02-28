extends ColorsTextureLoader
class_name KeyColorsTextureLoader

func initLoader(path:String,frames:int,params:Dictionary) -> KeyTextureLoader:
	return KeyTextureLoader.new(path,params.capitalised,frames)
