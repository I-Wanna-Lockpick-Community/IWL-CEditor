extends Node

var undoStack:Array[Array] = []
var saveBuffered:bool = false
var previousSaveBuffered:bool = false

enum TYPE {UndoSeparator, KeyChange, StarChange, CurseChange, GlistenChange, PropertyChange}

# handles the undo system for the Game
# a lot is copied over from Changes

func assignAndFollowStack(stack:Array[Array]) -> void:
	undoStack.assign(stack)
	for change in stack:
		if change[0] == TYPE.UndoSeparator: continue
		doChange(change)

func start() -> void:
	undoStack = []
	undoStack.append([TYPE.UndoSeparator,Game.player.position])

func bufferSave() -> void:
	saveBuffered = true

func applyChange(change:Array) -> Array:
	if !change: return change # an empty array means the change is cancelled
	doChange(change)
	undoStack.append(change)
	return change

func doChange(change:Array) -> void:
	var type:TYPE = change[0]
	match type:
		# color, before, after
		TYPE.KeyChange: Game.player.key[change[1]] = copy(change[3])
		TYPE.StarChange: Game.player.star[change[1]] = copy(change[3])
		TYPE.CurseChange: Game.player.curse[change[1]] = copy(change[3])
		TYPE.GlistenChange: Game.player.glisten[change[1]] = copy(change[3])
		# componenttype, id, property, before, after
		TYPE.PropertyChange: propertyChange_(change[1], change[2], change[3], change[5])
		_: assert(false)

func undoChange(change:Array) -> void:
	var type:TYPE = change[0]
	match type:
		# color, before, after
		TYPE.KeyChange: Game.player.key[change[1]] = copy(change[2])
		TYPE.StarChange: Game.player.star[change[1]] = copy(change[2])
		TYPE.CurseChange: Game.player.curse[change[1]] = copy(change[2])
		TYPE.GlistenChange: Game.player.glisten[change[1]] = copy(change[2])
		# componenttype, id, property, before, after
		TYPE.PropertyChange: propertyChange_(change[1], change[2], change[3], change[4])
		_: assert(false)

func newColorChange(type:TYPE, color:C.olors, after:Variant) -> Array:
	var before:Variant
	match type:
		TYPE.KeyChange: before = Game.player.key[color]
		TYPE.StarChange: before = Game.player.star[color]
		TYPE.CurseChange: before = Game.player.curse[color]
		TYPE.GlistenChange: before = Game.player.glisten[color]
		_: assert(false); return []
	if before == after or color == C.olors.NONE: return []
	return [type, color, copy(before), copy(after)]

func newPropertyChange(component:GameComponent, property:StringName, after:Variant) -> Array:
	return [TYPE.PropertyChange, Game.COMPONENTS.find(component.get_script()),
		component.id, property, copy(component.get(property)), copy(after)]

func propertyChange_(componentType:int, id:int, property:StringName, to:Variant) -> void:
	var component:GameComponent
	if Game.COMPONENTS[componentType] in Game.NON_OBJECT_COMPONENTS: component = Game.components.get(id)
	elif Game.COMPONENTS[componentType] in Game.NOTE_COMPONENTS: component = Game.notes.get(id)
	else: component = Game.objects.get(id)
	if !component: return
	component.set(property, copy(to))
	component.propertyGameChangedDo(property)
	component.queue_redraw()
	if component is Door:
		for lock in component.locks: lock.queue_redraw()

func process() -> void:
	if previousSaveBuffered and Game.player.previousIsOnFloor and Game.player.is_on_floor() and !Game.player.cantSavePrevious:
		saveBuffered = false
		undoStack.append([TYPE.UndoSeparator, Game.player.previousPosition])
	previousSaveBuffered = saveBuffered

func undo() -> bool:
	if len(undoStack) == 1: return false
	if undoStack[-1][0] == TYPE.UndoSeparator: undoStack.pop_back()
	saveBuffered = false
	previousSaveBuffered = false
	Game.player.pauseFrame = true
	Game.player.velocity = Vector2.ZERO
	while true:
		if undoStack[-1][0] == TYPE.UndoSeparator:
			Game.player.position = undoStack[-1][1]
			Game.player.dropMaster()
			Game.player.bufferCheckKeys()
			return true
		var change:Array = undoStack.pop_back()
		undoChange(change)
	return true # unreachable

func copy(value:Variant) -> Variant:
	if value is Array: return value.duplicate()
	else: return value
