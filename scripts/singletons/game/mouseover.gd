extends VBoxContainer
class_name Mouseover

var objectsWithMouseover:Array[GDScript] = [KeyBulk, Door, RemoteLock]
var panels:Array[MouseoverPanel] = []

func describe(objects:Array[GameObject], pos:Vector2, screenBottomRight:Vector2) -> void:
	objects = objects.filter(func(o:GameObject)->bool: return o.get_script() in objectsWithMouseover)
	if len(objects) == 0 or Game.pda.visible:
		visible = false
		return
	visible = true
	
	position = pos
	if position.x + size.x > screenBottomRight.x: position.x -= size.x
	if position.y + size.y > screenBottomRight.y: position.y -= size.y
	
	for i in max(0,len(objects) - len(panels)):
		var panel:MouseoverPanel = preload("res://scenes/mouseoverPanel.tscn").instantiate()
		add_child(panel)
		panels.append(panel)
	for i in max(0,len(panels) - len(objects)): panels.pop_back().queue_free()
	for i in len(objects): panels[i].describe(objects[i])
	
	size = Vector2.ZERO
