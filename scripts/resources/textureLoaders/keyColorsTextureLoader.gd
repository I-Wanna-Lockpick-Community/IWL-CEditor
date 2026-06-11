extends ColorsTextureLoader
class_name KeyColorsTextureLoader

func initLoader(path:String,frames:int,params:Dictionary) -> KeyTextureLoader:
	return KeyTextureLoader.new(path,params.capitalised,frames)

func colorSelect(color:C.ColorDef) -> bool: return color.keyTexture
func colorFrames(color:C.ColorDef) -> int: return color.keyTextureFrames
