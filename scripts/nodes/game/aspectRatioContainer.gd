@tool
extends Container
class_name BetterAspectRatioContainer

const RATIO:Vector2 = Vector2(800, 608)

func _notification(what:int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			for control in get_children():
				if control is not Control: continue
				if size.x*RATIO.y/size.y > RATIO.x:
					control.size = Vector2(size.y*RATIO.x/RATIO.y,size.y)
					control.position = Vector2((size.x-control.size.x)/2,0)
				elif size.x*RATIO.y/size.y < RATIO.x:
					control.size = Vector2(size.x,size.x*RATIO.y/RATIO.x)
					control.position = Vector2(0,(size.y-control.size.y)/2)
				else:
					control.size = Vector2(size.x,size.y)
					control.position = Vector2.ZERO

func _get_minimum_size() -> Vector2:
	var minSize:Vector2 = Vector2.ZERO
	for control in get_children():
		if control is not Control: continue
		if !control.visible: continue
		minSize = minSize.max(control.get_combined_minimum_size())
	return minSize
