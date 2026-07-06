extends GameTextureLoader
class_name LockPredefinedTextureLoader

var normal:LockConfigurationTextureLoader
var exact:LockConfigurationTextureLoader

# replaces $p with the configuration and exact or not
func _init(path:String,configurationSet:Array[Lock.CONFIGURATION]) -> void:
	normal = LockConfigurationTextureLoader.new(path.replace("$p", "$t"),configurationSet)
	exact = LockConfigurationTextureLoader.new(path.replace("$p", "$texact"),configurationSet)

func current(params:Array=[]) -> Texture2D: return (exact if params.pop_front() else normal).current(params)

class LockConfigurationTextureLoader extends TypeTextureLoader:
	var TYPES:Array[int] = []
	var TYPE_NAMES:Array[String] = []

	func _init(path:String, configurationSet:Array[Lock.CONFIGURATION]) -> void:
		TYPES.assign(configurationSet.map(func(configuration): return int(configuration)))
		TYPE_NAMES.assign(configurationSet.map(func(configuration): return Lock.CONFIGURATION_NAMES[configuration]))
		super(path,true)
	
	func types() -> Array[int]: return TYPES
	func typeNames() -> Array[String]: return TYPE_NAMES
