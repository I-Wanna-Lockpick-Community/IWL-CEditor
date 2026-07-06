extends IndexTextureLoader
class_name GoldIndexTextureLoader

func current(_params:Array=[]) -> Texture2D: return textures[Game.goldIndex % frames]
