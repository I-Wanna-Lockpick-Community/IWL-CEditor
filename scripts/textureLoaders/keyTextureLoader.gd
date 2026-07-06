extends TypeTextureLoader
class_name KeyTextureLoader

const TYPES:int = 7
enum TYPE {NORMAL, EXACT, STAR, UNSTAR, CURSE, UNCURSE, OPERATOR}
const TYPE_NAMES:Array[String] = ["Normal", "Exact", "Star", "Unstar", "Curse", "Uncurse", "Operator"]

func types() -> Array[int]: return rangei(TYPES)
func typeNames() -> Array[String]: return TYPE_NAMES
