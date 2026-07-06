extends ColorsTextureLoader
class_name LockColorsTextureLoader

func initLoader(path:String,frames:int,_params:Dictionary) -> LockTextureLoader:
	return LockTextureLoader.new(path,frames)
