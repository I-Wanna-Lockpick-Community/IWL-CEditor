extends Node

var undoStack:Array[RefCounted] = []
var saveBuffered:bool = false
var previousSaveBuffered:bool = false

static var CHANGE_TYPES:Array[GDScript] = [
	UndoSeparator,
	KeyChange, StarChange, CurseChange, GlistenChange,
	PropertyChange
]

# handles the undo system for the Game
# a lot is copied over from Changes

func assignAndFollowStack(stack:Array[RefCounted]) -> void:
	undoStack.assign(stack)
	for change in stack:
		if change is UndoSeparator: continue
		change.do()

func start() -> void:
	undoStack = []
	undoStack.append(UndoSeparator.new(Game.player.position))

func bufferSave() -> void:
	saveBuffered = true

func addChange(change:Change) -> Change:
	if change.cancelled: return null
	undoStack.append(change)
	return change

func process() -> void:
	if previousSaveBuffered and Game.player.previousIsOnFloor and Game.player.is_on_floor() and !Game.player.cantSavePrevious:
		saveBuffered = false
		undoStack.append(UndoSeparator.new(Game.player.previousPosition))
	previousSaveBuffered = saveBuffered

func undo() -> bool:
	if len(undoStack) == 1: return false
	if undoStack[-1] is UndoSeparator: undoStack.pop_back()
	saveBuffered = false
	previousSaveBuffered = false
	Game.player.pauseFrame = true
	Game.player.velocity = Vector2.ZERO
	while true:
		if undoStack[-1] is UndoSeparator:
			Game.player.position = undoStack[-1].position
			Game.player.dropMaster()
			Game.player.bufferCheckKeys()
			return true
		var change = undoStack.pop_back()
		change.undo()
	return true # unreachable

func copy(value:Variant) -> Variant:
	if value is PackedInt64Array: return value.duplicate()
	else: return value

@abstract class Change extends RefCounted:
	var cancelled:bool = false
	# is a singular recorded change
	@abstract func do() -> void
	@abstract func undo() -> void

	@abstract func serialise() -> Array
	# and also a static deserialise one. first element of the array should be the type

class UndoSeparator extends RefCounted:
	# indicates the start/end of an undo in the stack; also saves the player's position at that point
	var position:Vector2

	func _init(_position:Vector2) -> void:
		position = _position
	
	func _to_string() -> String:
		return "<UndoSeparator:"+str(position)+">"

	func serialise() -> Array: return [GameChanges.CHANGE_TYPES.find(UndoSeparator), position]
	static func deserialise(properties:Array) -> UndoSeparator: return UndoSeparator.new(properties[1])

@abstract class ColorChange extends Change:
	# a change to something in an array of player indexed by colors
	# like key and star
	static func array() -> StringName: return &""

	var color:Game.COLOR
	var after:Variant
	var before:Variant

	func _init(_color:Game.COLOR, _after:Variant, activate:bool=true) -> void:
		color = _color
		after = GameChanges.copy(_after)
		if activate:
			before = GameChanges.copy(Game.player.get(array())[color])
			if before == after or color == Game.COLOR.NONE:
				cancelled = true
				return
			do()
	
	func do() -> void: Game.player.get(array())[color] = GameChanges.copy(after)
	func undo() -> void: Game.player.get(array())[color] = GameChanges.copy(before)

	func _to_string() -> String:
		return "<ColorChange:"+str(color)+"."+array()+"->"+str(after)+">"
	
	func serialise() -> Array: return [GameChanges.CHANGE_TYPES.find(get_script()), color, before, after]
	static func deserialise(properties:Array) -> ColorChange:
		var change:ColorChange = GameChanges.CHANGE_TYPES[properties[0]].new(properties[1], properties[3], false)
		change.before = GameChanges.copy(properties[2])
		return change

class KeyChange extends ColorChange:
	# C major -> A minor, for example
	static func array() -> StringName: return &"key"

	func do() -> void:
		super()
		Game.bufferGateCheck()

class StarChange extends ColorChange:
	# a change to the starred state
	static func array() -> StringName: return &"star"

	func update() -> void: pass

class CurseChange extends ColorChange:
	# a change to the cursed state
	static func array() -> StringName: return &"curse"
	
class GlistenChange extends ColorChange:
	# a change to the glistening count
	static func array() -> StringName: return &"glisten"

	func do() -> void:
		super()
		Game.bufferGateCheck()

class PropertyChange extends Change:
	var id:int
	var property:StringName
	var after:Variant
	var before:Variant
	var type:GDScript
	
	func _init(component:GameComponent,_property:StringName,_after:Variant, activate:bool=true) -> void:
		id = component.id
		property = _property
		after = Changes.copy(_after)
		type = component.get_script()
		if activate:
			before = Changes.copy(component.get(property))
			if before == after:
				cancelled = true
				return
			do()

	func do() -> void: changeValue(after)
	func undo() -> void: changeValue(before)
	
	func changeValue(value:Variant) -> void:
		var component:GameComponent
		if type in Game.NON_OBJECT_COMPONENTS: component = Game.components.get(id)
		else: component = Game.objects.get(id)
		if !component: return
		component.set(property, Changes.copy(value))
		component.propertyGameChangedDo(property)
		component.queue_redraw()
		if component is Door:
			for lock in component.locks: lock.queue_redraw()
	
	func _to_string() -> String:
		return "<PropertyChange:"+str(id)+"."+str(property)+">"

	func serialise() -> Array: return [GameChanges.CHANGE_TYPES.find(PropertyChange), type in Game.NON_OBJECT_COMPONENTS, id, property, before, after]
	static func deserialise(properties:Array) -> PropertyChange:
		var component:GameComponent
		if properties[1]: component = Game.components.get(properties[2])
		else: component = Game.objects.get(properties[2])
		if !component: return null
		var change:PropertyChange = PropertyChange.new(component, properties[3], properties[5], false)
		change.before = GameChanges.copy(properties[4])
		return change
