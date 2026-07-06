extends TypeTextureLoader
class_name LockTextureLoader

func _init(path:String, _frames:int=1) -> void: super(path,true,_frames)

func types() -> Array[int]: return rangei(Lock.SIZE_TYPES)
func typeNames() -> Array[String]: return Lock.SIZE_TYPE_NAMES
