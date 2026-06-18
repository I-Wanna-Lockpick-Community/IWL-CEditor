extends Control
class_name Editor

@onready var world:World = %world
@onready var modes:Modes = %modes
@onready var gameCont:MarginContainer = %gameCont
@onready var focusDialog:FocusDialog = %focusDialog
@onready var quickSet:QuickSet = %quickSet
@onready var multiselect:Multiselect = %multiselect
@onready var paste:Button = %paste
@onready var otherObjects:OtherObjects = %otherObjects
@onready var topBar:TopBar = %topBar
@onready var settingsMenu:SettingsMenu = %settingsMenu
@onready var outline:Outline = %outline
var modsWindow:ModsWindow
var exportWindow:ExportWindow
var findProblems:FindProblems

@onready var saveAsDialog:FileDialog = %saveAsDialog
@onready var openDialog:FileDialog = %openDialog
@onready var unsavedChangesPopup:ConfirmationDialog = %unsavedChangesPopup
@onready var loadErrorPopup:AcceptDialog = %loadErrorPopup

@onready var editorCamera:Camera2D = %editorCamera
@onready var playtestCamera:Camera2D = %playtestCamera

@onready var gameViewport:SubViewport = %gameViewport
@onready var explainText:RichTextLabel = %explainText
@onready var placePreviewWorld:World = %placePreviewWorld

@onready var outlineViewport1:OutlineViewport = %outlineViewport1 # width: 1, r: multiselect
@onready var outlineViewport2:OutlineViewport = %outlineViewport2 # width: 2, r: component, g: object

@onready var fileMenu:FileMenu = %fileMenu

var previewComponents:Array[GameComponent] = []

enum MODE {SELECT, TILE, KEY, DOOR, OTHER, PASTE}
var mode:MODE = MODE.SELECT

var mouseWorldPosition:Vector2
var mouseTilePosition:Vector2i

var cameraZoom:float = 1
var targetCameraZoom:float = 1
var zoomPoint:Vector2 # the point where the latest zoom was targetted

var objectHovered:GameObject
var componentHovered:GameComponent # you can hover both a door and a lock at the same time so

enum DRAG_MODE {POSITION, SIZE_DIAG, SIZE_VERT, SIZE_HORIZ}
enum SIZE_DRAG_PIVOT {TOP_LEFT, TOP, TOP_RIGHT, LEFT, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT, NONE}
const SIZE_DRAG_DIRECTIONS:Array[Vector2] = [Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1), Vector2(-1,0), Vector2(1,0), Vector2(-1,1), Vector2(0,1), Vector2(1,1), Vector2(0,0)]
var componentDragged:GameComponent
var dragMode:DRAG_MODE
var dragPivotRect:Rect2 # the pivot for size dragging
var dragHandlePosition:Vector2
var previousDragPosition:Vector2
var dragHandle:Vector2 # direction of the handle (initially), so that size_vert and size_horiz behave as they do
var levelBoundsObject:GameObject = PlaceholderObject.new() # spoof

var lockBufferConvert:bool = false
var connectionSource:GameObject # for pulling connections between remote locks and doors

var tileSize:Vector2i = Vector2i(32,32)

var settingsOpen:bool = false

var drawMain:RID
var drawAutoRunGradient:RID
var autoRunTimer:float = 2

var screenshot:Image
var drawThumbnail:RID
var thumbnailHideDescription:bool = false
var thumbnailEntireLevel:bool = true
var thumbnailWithText:bool = true

var edgeResizing:bool = false

var playerObject:GameObject = PlayerPlaceholderObject.new()

func _ready() -> void:
	Mods.editor = self
	Saving.editor = self
	Explainer.editor = self
	drawMain = RenderingServer.canvas_item_create()
	drawAutoRunGradient = RenderingServer.canvas_item_create()
	drawThumbnail = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawAutoRunGradient, Game.TEXT_GRADIENT_MATERIAL)
	RenderingServer.canvas_item_set_z_index(drawThumbnail,1)
	RenderingServer.canvas_item_set_parent(drawMain, %gameCont.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawAutoRunGradient, %gameCont.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawThumbnail, %thumbnail.get_canvas_item())
	Game.setWorld(%world)
	%settingsText.text = "IWLCEditor v" + ProjectSettings.get_setting("application/config/version")
	settingsMenu.gameSettings.editor = self
	Saving.editorReady()
	if OS.has_feature('web'):
		fileMenu.menu.remove_item(5)
		fileMenu.menu.remove_item(3)
	if !FileAccess.file_exists("user://config.ini"): settingsMenu.closed()
	settingsMenu.opened()
	%screenshotInnerViewport.world_2d = %gameViewport.world_2d
	Game.camera = playtestCamera
	get_window().files_dropped.connect(func(files): Saving.loadFile(files[0]))
	playerObject.size = Vector2(12,21)
	playerObject.id = -1
	%screenshotViewportCont.visible = false

func _process(delta:float) -> void:
	queue_redraw()
	var scaleFactor:float = (targetCameraZoom/editorCamera.zoom.x)**0.2
	if abs(scaleFactor - 1) < 0.0001:
		editorCamera.zoom = Vector2(targetCameraZoom,targetCameraZoom)
		if targetCameraZoom == 1: editorCamera.position = round(editorCamera.position)
	else:
		editorCamera.zoom *= scaleFactor
		editorCamera.position += (1-1/scaleFactor) * (worldspaceToScreenspace(zoomPoint)-gameCont.position) / editorCamera.zoom * Game.uiScale
		multiselect.update()
	
	if settingsOpen: tileSize = Vector2i(32,32)
	else:
		if Input.is_action_pressed(&"heldTileSize4") and Input.is_action_pressed(&"heldTileSize16"): tileSize = Vector2i(1,1)
		elif Input.is_action_pressed(&"heldTileSize4"): tileSize = Vector2i(4,4)
		elif Input.is_action_pressed(&"heldTileSize16"): tileSize = Vector2i(16,16)
		else: tileSize = Vector2i(32,32)
		
	if Game.playState != Game.PLAY_STATE.PLAY and !focusDialog.focused and get_window().has_focus() and has_focus():
		editorCamera.position += Vector2(Input.get_axis(&"editCameraLeft", &"editCameraRight"),Input.get_axis(&"editCameraUp", &"editCameraDown"))*delta/editorCamera.zoom*700


	mouseWorldPosition = screenspaceToWorldspace(get_global_mouse_position())
	mouseTilePosition = Vector2i(floor(mouseWorldPosition / Vector2(tileSize))) * tileSize
	if Game.playState == Game.PLAY_STATE.PLAY or settingsOpen: %gameViewportDisplay.material.set_shader_parameter(&"mousePosition",Vector2(-1e7,-1e7)) # probably far away enough
	else: %gameViewportDisplay.material.set_shader_parameter(&"mousePosition",mouseWorldPosition - Vector2(Game.levelBounds.position))
	%gameViewportDisplay.material.set_shader_parameter(&"screenPosition",screenspaceToWorldspace(Vector2.ZERO))
	RenderingServer.global_shader_parameter_set(&"VIEWPORT_POS",screenspaceToWorldspace(gameCont.position))
	if Game.playState == Game.PLAY_STATE.PLAY: cameraZoom = playtestCamera.zoom.x
	else: cameraZoom = editorCamera.zoom.x
	RenderingServer.global_shader_parameter_set(&"RCAMERA_ZOOM", 1/cameraZoom)
	%gameViewportDisplay.material.set_shader_parameter(&"tileSize", Vector2i(800, 608) if settingsOpen else tileSize)
	componentHovered = null
	if !componentDragged:
		objectHovered = null
		if !Input.is_action_pressed(&"heldKeepMode") and !settingsOpen:
			for object in Game.objectsParent.get_children():
				if mode == MODE.SELECT or Game.playState == Game.PLAY_STATE.PLAY or (mode == MODE.KEY and object is KeyBulk) or (mode == MODE.DOOR and object is Door) or (mode == MODE.OTHER and object.get_script() == otherObjects.selected):
					if Rect2(object.getDrawPosition(), object.size).has_point(mouseWorldPosition) and (Game.playState != Game.PLAY_STATE.PLAY or object.active):
						objectHovered = object
			if focusDialog.focused is Door:
				for lock in focusDialog.focused.locks:
					if Rect2(lock.getDrawPosition(), lock.size).has_point(mouseWorldPosition):
						componentHovered = lock
			elif focusDialog.focused is KeyCounter:
				for element in focusDialog.focused.elements:
					if Rect2(element.getDrawPosition(), element.getHoverSize()).has_point(mouseWorldPosition):
						componentHovered = element
	%mouseover.describe(objectHovered if Game.playState == Game.PLAY_STATE.PLAY else null, %gameViewportDisplay.get_local_mouse_position(), %gameViewportDisplay.size)
	Game.tiles.z_index = 3 if mode == MODE.TILE and Game.playState != Game.PLAY_STATE.PLAY else -3

	if autoRunTimer < 2:
		autoRunTimer += delta
		queue_redraw()
		if autoRunTimer >= 2: autoRunTimer = 2

	%placePreviewWorld.visible = Game.playState != Game.PLAY_STATE.PLAY and !settingsOpen
	placePreviewWorld.tiles.position = floor(mouseWorldPosition/32)*32
	placePreviewWorld.tilesDropShadow.position = floor(mouseWorldPosition/32)*32 + Vector2(3,3)
	placePreviewWorld.objectsParent.position = mouseTilePosition
	%placePreviewCamera.position = editorCamera.position
	%placePreviewCamera.zoom = editorCamera.zoom

	if Mods.bufferedModsChanged:
		get_tree().call_group("modUI", "changedMods")
		Mods.bufferedModsChanged = false

func _gui_input(event:InputEvent) -> void:
	if !objectHovered: objectHovered = null
	if !componentHovered: componentHovered = null
	if event is InputEventMouse:
		if Game.playState == Game.PLAY_STATE.PLAY:
			mouse_default_cursor_shape = CURSOR_ARROW
		else:
			# move camera
			if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
				editorCamera.position -= event.relative / cameraZoom * Game.uiScale
			if !(settingsOpen and !settingsMenu.levelSettings.visible) and event is InputEventMouseButton and event.is_pressed():
				match event.button_index:
					MOUSE_BUTTON_WHEEL_UP: zoomCamera(1.25)
					MOUSE_BUTTON_WHEEL_DOWN: zoomCamera(0.8)
			# modes
			if isLeftUnclick(event) or isRightUnclick(event):
				if componentDragged: stopDrag()
				Changes.bufferSave()
			# set mouse cursor
			match multiselect.state:
				Multiselect.STATE.DRAGGING: mouse_default_cursor_shape = CURSOR_DRAG
				Multiselect.STATE.SELECTING: mouse_default_cursor_shape = CURSOR_ARROW
				Multiselect.STATE.HOLDING:
					if componentDragged:
						match dragMode:
							DRAG_MODE.POSITION: mouse_default_cursor_shape = CURSOR_DRAG
							DRAG_MODE.SIZE_DIAG:
								var diffSign:Vector2 = rectSign(dragPivotRect, dragHandlePosition)
								match diffSign:
									Vector2(-1,-1), Vector2(1,1): mouse_default_cursor_shape = CURSOR_FDIAGSIZE
									Vector2(-1,1), Vector2(1,-1): mouse_default_cursor_shape = CURSOR_BDIAGSIZE
									Vector2(-1,0), Vector2(1,0): mouse_default_cursor_shape = CURSOR_HSIZE
									Vector2(0,-1), Vector2(0,1): mouse_default_cursor_shape = CURSOR_VSIZE
									Vector2(0,0): mouse_default_cursor_shape = CURSOR_MOVE
							DRAG_MODE.SIZE_VERT: mouse_default_cursor_shape = CURSOR_VSIZE
							DRAG_MODE.SIZE_HORIZ: mouse_default_cursor_shape = CURSOR_HSIZE
					else: mouse_default_cursor_shape = CURSOR_ARROW
			if settingsOpen:
				settingsMenu.mouse_default_cursor_shape = mouse_default_cursor_shape
				if componentDragged: return dragComponent()
				return settingsMenu.receiveMouseInput(event)
			# connection pulling
			if connectionSource and isLeftClick(event):
				if connectionSource is RemoteLock and objectHovered is Door: connectionSource._connectTo(objectHovered)
				if connectionSource is Door and objectHovered is RemoteLock: objectHovered._connectTo(connectionSource)
				focusDialog.focus(connectionSource)
				connectionSource.queue_redraw()
				connectionSource = null
				return
			# multiselect
			if multiselect.receiveMouseInput(event): return
			elif multiselect.state == Multiselect.STATE.HOLDING:
				if isLeftClick(event) or isRightClick(event): multiselect.deselect()
			else: return
			# size drag handles
			if focusDialog.componentFocused is Lock and focusDialog.focused.type != Door.TYPE.SIMPLE:
				if focusDialog.componentFocused.receiveMouseInput(event): return
			elif objectHovered:
				if objectHovered.receiveMouseInput(event): return
			# dragging
			if componentDragged: dragComponent(); return
			# other
			var inBounds:bool = Mods.active(&"OutOfBounds") or Game.levelBounds.has_point(mouseTilePosition)
			match mode:
				MODE.SELECT:
					if isLeftClick(event): # if youre hovering something and you leftclick, focus it
						if componentHovered:
							focusDialog.focusComponent(componentHovered)
						else: focusDialog.defocusComponent()
						if componentHovered is Lock and componentHovered.parent.type != Door.TYPE.SIMPLE: startPositionDrag(componentHovered)
						elif componentHovered is KeyCounterElement: startPositionDrag(componentHovered)
						elif objectHovered: startPositionDrag(objectHovered)
						else:
							focusDialog.defocus()
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and event is InputEventMouseMotion and multiselect.state == Multiselect.STATE.HOLDING: multiselect.startSelect()
				MODE.TILE:
					if inBounds:
						if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
							Changes.addChange(Changes.TileChange.new(floor(mouseWorldPosition/32),true))
							focusDialog.defocus()
						elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
							Changes.addChange(Changes.TileChange.new(floor(mouseWorldPosition/32),false))
							focusDialog.defocus()
				MODE.KEY:
					if isLeftClick(event): # if youre hovering a key and you leftclick, focus it
						if objectHovered is KeyBulk:
							startPositionDrag(objectHovered)
						else: focusDialog.defocus()
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						if objectHovered is not KeyBulk and inBounds:
							var key:KeyBulk = Changes.addChange(Changes.CreateComponentChange.new(KeyBulk,{&"position":mouseTilePosition})).result
							focusDialog.defocus()
							if !Input.is_action_pressed(&"heldKeepMode"):
								modes.setMode(MODE.SELECT)
								startPositionDrag(key)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						if objectHovered is KeyBulk:
							Changes.addChange(Changes.DeleteComponentChange.new(objectHovered))
							Changes.bufferSave()
				MODE.DOOR:
					if isLeftClick(event):
						if componentHovered:
							focusDialog.focusComponent(componentHovered)
						else: focusDialog.defocusComponent()
						if componentHovered is Lock: startPositionDrag(componentHovered)
						elif objectHovered is Door: startPositionDrag(objectHovered)
						else:
							if objectHovered is not Door and inBounds:
								var door:Door = Changes.addChange(Changes.CreateComponentChange.new(Door,{&"position":mouseTilePosition})).result
								startSizeDrag(door)
								Changes.addChange(Changes.CreateComponentChange.new(Lock,{&"position":Vector2.ZERO,&"parentId":door.id}))
								if !Input.is_action_pressed(&"heldKeepMode"):
									modes.setMode(MODE.SELECT)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						if objectHovered is Door:
							Changes.addChange(Changes.DeleteComponentChange.new(objectHovered))
							Changes.bufferSave()
				MODE.OTHER:
					if isLeftClick(event):
						if componentHovered is KeyCounterElement and otherObjects.selected == KeyCounter: startPositionDrag(componentHovered)
						elif objectHovered and objectHovered.get_script() == otherObjects.selected:
							startPositionDrag(objectHovered)
						else: focusDialog.defocus()
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						if (!objectHovered or objectHovered.get_script() != otherObjects.selected) and inBounds:
							var object:GameObject = Changes.addChange(Changes.CreateComponentChange.new(otherObjects.selected,{&"position":mouseTilePosition})).result
							focusDialog.defocus()
							if otherObjects.selected == KeyCounter:
								Changes.addChange(Changes.CreateComponentChange.new(KeyCounterElement,{&"position":Vector2(12,12),&"parentId":object.id}))
							if !Input.is_action_pressed(&"heldKeepMode"):
								modes.setMode(MODE.SELECT)
								startPositionDrag(object)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						if objectHovered and objectHovered.get_script() == otherObjects.selected:
							Changes.addChange(Changes.DeleteComponentChange.new(objectHovered))
							Changes.bufferSave()
				MODE.PASTE:
					if isLeftClick(event):
						multiselect.paste()
						if !Input.is_action_pressed(&"heldKeepMode"):
							modes.setMode(MODE.SELECT)

func stopDrag() -> void:
	if componentDragged == levelBoundsObject:
		componentDragged = null
		return
	if sizeDragging():
		if !Mods.active(&"MoreLockSizes") and componentDragged is Lock and componentDragged.parent.type != Door.TYPE.SIMPLE:
			componentDragged._coerceSize()
		if componentDragged is GameObject: focusDialog.focus(componentDragged)
		else: focusDialog.focusComponent(componentDragged)
	elif dragMode == DRAG_MODE.POSITION:
		if lockBufferConvert:
			lockBufferConvert = false
			convertLock(componentDragged)
		if componentDragged:
			if componentDragged.get_script() in Game.NON_OBJECT_COMPONENTS: focusDialog.focusComponent(componentDragged)
			else: focusDialog.focus(componentDragged)
	componentDragged = null

static func convertLock(lock:Lock) -> RemoteLock:
	var remoteLock = Changes.addChange(Changes.CreateComponentChange.new(RemoteLock,{&"position":lock.position+lock.parent.position})).result
	for property in Lock.PROPERTIES:
		if property not in [&"id", &"position", &"parentId", &"index"]:
			Changes.addChange(Changes.PropertyChange.new(remoteLock,property,lock.get(property)))
	remoteLock._connectTo(lock.parent)
	if lock.parent.type == Door.TYPE.SIMPLE: Changes.addChange(Changes.PropertyChange.new(lock.parent,&"type",Door.TYPE.COMBO))
	Changes.addChange(Changes.DeleteComponentChange.new(lock))
	return remoteLock

func startPositionDrag(component:GameComponent) -> void:
	if component is GameObject: focusDialog.focus(component)
	else: focusDialog.focusComponent(component)
	componentDragged = component
	dragMode = DRAG_MODE.POSITION
	previousDragPosition = mouseTilePosition

func startSizeDrag(component:GameComponent, handle:Vector2=Vector2(1,1)) -> void:
	focusDialog.defocus()
	componentDragged = component
	var minSize:Vector2
	if component is Door: minSize = Vector2(32,32)
	elif component is Lock or component is RemoteLock: minSize = Vector2(18,18)
	elif component is KeyCounter: minSize = Vector2(KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.SHORT],63)
	elif component is FloatingTile: minSize = Vector2(16,16)
	elif component == levelBoundsObject: minSize = Vector2(800, 608)
	if handle.x and handle.y: dragMode = DRAG_MODE.SIZE_DIAG
	elif handle.x: dragMode = DRAG_MODE.SIZE_HORIZ; minSize.y = componentDragged.size.y
	elif handle.y: dragMode = DRAG_MODE.SIZE_VERT; minSize.x = componentDragged.size.x
	
	var snappedMousePosition:Vector2 = mouseWorldPosition.snapped(tileSize)

	var parentPosition:Vector2 = component.parent.position if component.get_script() in Game.NON_OBJECT_COMPONENTS else Vector2i.ZERO
	dragPivotRect = Rect2(component.position + (component.size - minSize) * Vector2.ZERO.max(-handle), minSize)
	dragHandlePosition = snappedMousePosition - parentPosition
	previousDragPosition = snappedMousePosition
	dragHandle = handle

func dragComponent() -> void: # returns whether or not an object is being dragged, for laziness
	var snappedMousePosition:Vector2 = mouseWorldPosition.snapped(tileSize)
	var dragOffset:Vector2
	if dragMode == DRAG_MODE.POSITION: dragOffset = Vector2(mouseTilePosition) - previousDragPosition
	else: dragOffset = snappedMousePosition - previousDragPosition
	lockBufferConvert = false # whether or not to buffer a conversion to remotelock
	var bounds:Rect2
	var allowOutOfBounds:bool = Mods.active(&"OutOfBounds")
	if componentDragged is Lock:
		allowOutOfBounds = (Mods.active(&"RemoteLocks") and dragMode == DRAG_MODE.POSITION) or Mods.active(&"DisconnectedLocks")
		bounds = Rect2(componentDragged.getOffset(), componentDragged.parent.size)
	else: bounds = Game.levelBounds
	var innerBounds:Rect2 = bounds.grow(-1) # require strictly within
	match dragMode:
		DRAG_MODE.POSITION:
			if componentDragged is KeyCounterElement:
				var dragPosition = mouseWorldPosition - Vector2(0,20)
				if componentDragged.index > 0 and (componentDragged.getDrawPosition()).y - dragPosition.y >= 20:
					componentDragged.parent._swapElements(componentDragged.index, componentDragged.index-1)
				elif componentDragged.index < len(componentDragged.parent.elements) - 1 and (componentDragged.getDrawPosition()).y - dragPosition.y <= -20:
					componentDragged.parent._swapElements(componentDragged.index, componentDragged.index+1)
			else:
				var goingTo:Rect2 = Rect2(componentDragged.position + dragOffset, componentDragged.size)
				if !bounds.intersects(goingTo):
					if !allowOutOfBounds:
						dragOffset += snappedAway(Vector2.ZERO.max(innerBounds.position - goingTo.end) - Vector2.ZERO.max(goingTo.position - innerBounds.end), Vector2(tileSize))
					elif componentDragged is Lock and Mods.active(&"RemoteLocks") and !Mods.active(&"DisconnectedLocks"): lockBufferConvert = true
				previousDragPosition += dragOffset
				Changes.addChange(Changes.PropertyChange.new(componentDragged,&"position", componentDragged.position + dragOffset))
		DRAG_MODE.SIZE_DIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ:
			dragHandlePosition += dragOffset
			var toPosition:Vector2 = dragPivotRect.position
			# dragging up/left
			toPosition += snappedTrunc(dragHandlePosition - dragPivotRect.position, Vector2(tileSize)) * Vector2.ZERO.max(sign(dragPivotRect.position - dragHandlePosition))
			# dragging down/right
			toPosition += (dragPivotRect.size + snappedTrunc(dragHandlePosition - dragPivotRect.end, Vector2(tileSize))) * Vector2.ZERO.max(sign(dragHandlePosition - dragPivotRect.position))

			# keep in bounds
			var effectiveDragPivotRect:Rect2 = dragPivotRect
			if !allowOutOfBounds:
				effectiveDragPivotRect = effectiveDragPivotRect.expand(dragPivotRect.position + snappedAway(Vector2.ZERO.max(innerBounds.position - dragPivotRect.position) - Vector2.ZERO.max(dragPivotRect.position - innerBounds.end), Vector2(tileSize)))

			# keycounter has only a few possible widths
			if componentDragged is KeyCounter:
				toPosition -= effectiveDragPivotRect.position
				if Mods.active(&"MoreKeyCounterWidths") and toPosition.x <= effectiveDragPivotRect.size.x - KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.EXLONG]: toPosition.x = effectiveDragPivotRect.size.x - KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.EXLONG]
				elif Mods.active(&"MoreKeyCounterWidths") and toPosition.x <= effectiveDragPivotRect.size.x - KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.VLONG]: toPosition.x = effectiveDragPivotRect.size.x - KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.VLONG]
				elif toPosition.x <= effectiveDragPivotRect.size.x - KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.LONG]: toPosition.x = effectiveDragPivotRect.size.x - KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.LONG]
				elif toPosition.x <= effectiveDragPivotRect.size.x - KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.MEDIUM]: toPosition.x = effectiveDragPivotRect.size.x - KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.MEDIUM]
				elif Mods.active(&"MoreKeyCounterWidths") and toPosition.x >= KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.EXLONG]: toPosition.x = KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.EXLONG]
				elif Mods.active(&"MoreKeyCounterWidths") and toPosition.x >= KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.VLONG]: toPosition.x = KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.VLONG]
				elif toPosition.x >= KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.LONG]: toPosition.x = KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.LONG]
				elif toPosition.x >= KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.MEDIUM]: toPosition.x = KeyCounter.WIDTH_AMOUNT[KeyCounter.WIDTH.MEDIUM]
				else: toPosition.x = 0
				toPosition.y = 0
				toPosition += effectiveDragPivotRect.position
				if effectiveDragPivotRect.grow(-1).has_point(toPosition):
					previousDragPosition += dragOffset
					return

			var toRect:Rect2 = effectiveDragPivotRect.expand(toPosition)
			if componentDragged is Door:
				for lock in componentDragged.locks:
					var doorInnerBounds:Rect2 = Rect2(lock.getOffset(), toRect.size).grow(-1)
					var lockGoingTo:Rect2 = Rect2(lock.position-toRect.position+componentDragged.position, lock.size) # keep relative position even if the door moves
					lockGoingTo.position += snappedAway(Vector2.ZERO.max(doorInnerBounds.position - lockGoingTo.end) - Vector2.ZERO.max(lockGoingTo.position - doorInnerBounds.end), Vector2(tileSize)) # keep in bounds
					Changes.addChange(Changes.PropertyChange.new(lock,&"position",lockGoingTo.position))
			previousDragPosition += dragOffset
			if componentDragged == levelBoundsObject:
				Changes.addChange(Changes.LevelResizeChange.new(toRect))
			else:
				Changes.addChange(Changes.PropertyChange.new(componentDragged,&"position",toRect.position))
				Changes.addChange(Changes.PropertyChange.new(componentDragged,&"size",toRect.size))

func _input(event:InputEvent) -> void:
	if quickSet.component: quickSet.receiveInput(event); return
	if event is InputEventKey and event.is_pressed():
		if settingsOpen:
			if !settingsMenu.has_focus(): return
			if eventIs(event, &"editHome"): home()
		elif Game.playState == Game.PLAY_STATE.PLAY:
			# IN PLAY
			if eventIs(event, &"gameAutoRun", false): autoRun()
			match event.keycode:
				KEY_ESCAPE: _toggleSettingsMenu(true)
				_: Game.player.receiveKey(event)
		else:
			# IN EDIT
			if otherObjects.objectSearch.has_focus():
				match event.keycode:
					KEY_ESCAPE: grab_focus()
					KEY_TAB: otherObjects._searchSubmitted()
				return
			if focusDialog.interacted and focusDialog.interacted.receiveKey(event): return
			elif focusDialog.focused and focusDialog.receiveKey(event): return
			elif focusDialog.interacted and focusDialog.interacted.receiveUnhandledKey(event): return
			elif eventIs(event, &"editStartPlaytest") and !topBar.play.disabled: await get_tree().process_frame; Game.playTest(Game.levelStart)
			elif eventIs(event, &"editStartPlaytestFromState") and !topBar.play.disabled: await get_tree().process_frame; Game.playTest(Game.latestSpawn)
			elif eventIs(event, &"editStopPlaytest") and Game.playState == Game.PLAY_STATE.PAUSED: Game.stopTest()
			elif eventIs(event, &"editModeSelect"): modes.setMode(MODE.SELECT); focusDialog.defocus(); componentDragged = null; multiselect.deselect()
			elif eventIs(event, &"editModeTile"): modes.setMode(MODE.TILE)
			elif eventIs(event, &"editModeKey"): modes.setMode(MODE.KEY)
			elif eventIs(event, &"editModeDoor"): modes.setMode(MODE.DOOR)
			elif eventIs(event, &"editModeOther"): modes.setMode(MODE.OTHER)
			elif eventIs(event, &"editObjectSearch"): otherObjects.objectSearch.grab_focus()
			elif eventIs(event, &"editPipette"): pipette()
			elif eventIs(event, &"editOpenSettings"): _toggleSettingsMenu(true)
			elif eventIs(event, &"editNew"): fileMenu.optionPressed(0)
			elif eventIs(event, &"editOpen"): fileMenu.optionPressed(1)
			elif eventIs(event, &"editSave"): fileMenu.optionPressed(2)
			elif eventIs(event, &"editSaveAs") and !OS.has_feature('web'): fileMenu.optionPressed(3)
			elif eventIs(event, &"editExport"): fileMenu.optionPressed(4)
			elif eventIs(event, &"editHome"): home()
			elif eventIs(event, &"editCopy"): multiselect.copySelection()
			elif eventIs(event, &"editCut"): multiselect.copySelection(); multiselect.delete()
			elif eventIs(event, &"editPaste") and multiselect.clipboard != []: modes.setMode(MODE.PASTE)
			elif eventIs(event, &"editUndo"): multiselect.deselect(); Changes.undo()
			elif eventIs(event, &"editRedo"): multiselect.deselect(); Changes.redo()
			elif eventIs(event, &"editDrag"):
				if focusDialog.componentFocused and !(focusDialog.componentFocused.parent is Door and focusDialog.componentFocused.parent.type == Door.TYPE.SIMPLE): startPositionDrag(focusDialog.componentFocused)
				elif focusDialog.focused: startPositionDrag(focusDialog.focused)
				elif multiselect.selected:
					multiselect.drag()
				focusDialog.defocus()
			elif eventIs(event, &"editDelete"): multiselect.delete()
			match event.keycode:
				KEY_TAB: grab_focus()
				KEY_F2: takeScreenshot()
				KEY_F3: takeThumbnailScreenshot(thumbnailWithText)

static func eventIs(event:InputEvent, action:StringName, exactMatch:bool=true) -> bool: return event.is_action_pressed(action, false, exactMatch)

func home() -> void:
	targetCameraZoom = 1
	zoomPoint = levelStartCameraCenter(Vector2(800,608)) + Vector2(400,304)
	editorCamera.position = zoomPoint - gameCont.size / (cameraZoom/Game.uiScale*2)

func zoomCamera(factor:float) -> void:
	targetCameraZoom *= factor
	zoomPoint = mouseWorldPosition
	if abs(targetCameraZoom - 1) < 0.001: targetCameraZoom = 1
	if targetCameraZoom < 0.001: targetCameraZoom = 0.001
	if targetCameraZoom > 1000: targetCameraZoom = 1000

func pipette() -> void:
	multiselect.deselect()
	focusDialog.defocus()
	if objectHovered:
		multiselect.selectRect.position = objectHovered.position
		multiselect.clipboard.assign([multiselect.createObjectCopy(objectHovered)])
		paste.disabled = false
		modes.setMode(MODE.PASTE)
		@warning_ignore("integer_division")
	elif Game.tiles.get_cell_source_id(mouseTilePosition/32) != -1: modes.setMode(MODE.TILE)
	else: modes.setMode(MODE.SELECT)

func worldspaceToScreenspace(vector:Vector2) -> Vector2:
	if Game.playState == Game.PLAY_STATE.PLAY: return (vector - playtestCamera.get_screen_center_position())*playtestCamera.zoom/Game.uiScale + gameCont.position + gameCont.size/2
	else: return (vector - editorCamera.position)*editorCamera.zoom/Game.uiScale + gameCont.position

func screenspaceToWorldspace(vector:Vector2) -> Vector2:
	if Game.playState == Game.PLAY_STATE.PLAY: return (vector - gameCont.position - gameCont.size/2)/playtestCamera.zoom*Game.uiScale + playtestCamera.get_screen_center_position()
	return (vector - gameCont.position)/editorCamera.zoom*Game.uiScale + editorCamera.position

static func isLeftClick(event:InputEvent) -> bool: return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
static func isRightClick(event:InputEvent) -> bool: return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT
static func isLeftUnclick(event:InputEvent) -> bool: return event is InputEventMouseButton and !event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
static func isRightUnclick(event:InputEvent) -> bool: return event is InputEventMouseButton and !event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT

func sizeDragging() -> bool: return dragMode in [DRAG_MODE.SIZE_DIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ]

static func rectSign(rect:Rect2, point:Vector2) -> Vector2: # the "sign" of a point minus a rectangle, ie. where it is in relation
	var signX:float = 0
	var signY:float = 0
	if point.x < rect.position.x: signX = -1
	if point.x >= rect.end.x: signX = 1
	if point.y < rect.position.y: signY = -1
	if point.y >= rect.end.y: signY = 1
	return Vector2(signX, signY)

static func snappedAway(vector:Variant, to:Variant) -> Variant: # snap, round away from 0
	return sign(vector) * ceil(abs(vector)/to)*to

static func snappedTrunc(vector:Variant, to:Variant) -> Variant: # snap, round towards 0
	return sign(vector) * floor(abs(vector)/to)*to

func scrollIntoView(component:GameComponent) -> void:
	var rect:Rect2 = Rect2(component.getDrawPosition()-Vector2(16,16), component.size+Vector2(32,32))
	var screenRect:Rect2 = Rect2(screenspaceToWorldspace(gameCont.position), gameCont.size/editorCamera.zoom)
	if rect.size.x > screenRect.size.x: zoomCamera(0.8**ceil(log(screenRect.size.x/rect.size.x)/-0.2231435513))
	if rect.size.y > screenRect.size.y: zoomCamera(0.8**ceil(log(screenRect.size.y/rect.size.y)/-0.2231435513))
	editorCamera.zoom = Vector2(targetCameraZoom,targetCameraZoom)
	screenRect = Rect2(screenspaceToWorldspace(gameCont.position), gameCont.size/editorCamera.zoom)
	editorCamera.position = editorCamera.position.clamp(rect.end-screenRect.size, rect.position)

func _toggleSettingsMenu(toggled_on:bool) -> void:
	%toggleSettingsMenu.button_pressed = toggled_on
	quickSet.applyOrCancel()
	%settingsMenu.visible = toggled_on
	%settingsText.visible = toggled_on
	%explainText.visible = !toggled_on
	%placePreviewWorld.visible = !toggled_on
	settingsOpen = toggled_on
	get_tree().call_group(&"hotkeyButton", &"queue_redraw")
	topBar._updateButtons()
	if toggled_on:
		focusDialog.defocus()
		%settingsMenu.opened()
		%settingsMenu.grab_focus()
	else:
		%settingsMenu.closed()
		grab_focus()

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawAutoRunGradient)
	var autoRunAlpha:float = abs(sin(autoRunTimer*PI))
	if autoRunAlpha > 0:
		TextDraw.outlinedGradient(Game.FMINIID,drawMain,drawAutoRunGradient,
			"[%s] Auto-Run is " % Explainer.hotkeyMap(&"gameAutoRun") + ("on" if Game.autoRun else "off"),
			Color(Color("#e6ffe6") if Game.autoRun else Color("#dcffe6"),autoRunAlpha),
			Color(Color("#e6c896") if Game.autoRun else Color("#64dc8c"),autoRunAlpha),
			Color(Color.BLACK,autoRunAlpha),12,Vector2(4,20)
		)
	if Game.playState == Game.PLAY_STATE.PLAY and Game.player.cameraAnimVal > 0:
		var topLeft:Vector2 = - Vector2(8,8) + Vector2(16,16)*Game.player.cameraAnimVal
		var bottomRight:Vector2 = gameCont.size + Vector2(8,8) - Vector2(16,16)*Game.player.cameraAnimVal
		RenderingServer.canvas_item_add_polyline(drawMain, [
			topLeft, Vector2(bottomRight.x, topLeft.y), bottomRight, Vector2(topLeft.x, bottomRight.y), topLeft-Vector2(0,1)
		], [Color.BLACK,Color.BLACK,Color.BLACK,Color.BLACK])
		topLeft -= Vector2(4,4)
		bottomRight += Vector2(4,4)
		RenderingServer.canvas_item_add_polyline(drawMain, [
			topLeft, Vector2(bottomRight.x, topLeft.y), bottomRight, Vector2(topLeft.x, bottomRight.y), topLeft-Vector2(0,1)
		], [Color.BLACK,Color.BLACK,Color.BLACK,Color.BLACK])
		TextDraw.outlined(Game.FPRESENTS, drawMain, "[%s] to zoom" % Explainer.hotkeyMap(&"gameAction"),Color(Color.WHITE,Game.player.cameraAnimVal),Color(Color.BLACK,Game.player.cameraAnimVal),14,Vector2(11,gameCont.size.y-16))
		TextDraw.outlined(Game.FPRESENTS, drawMain, "[%s] to exit" % Explainer.hotkeyMap(&"gameCamera"),Color(Color.WHITE,Game.player.cameraAnimVal),Color(Color.BLACK,Game.player.cameraAnimVal),14,gameCont.size+Vector2(-108,-16))

func autoRun() -> void:
	Game.autoRun = !Game.autoRun
	AudioManager.play(preload("res://resources/sounds/autoRun.wav"), 1.0, 1.0 if Game.autoRun else 0.7)
	autoRunTimer = 0
	%settingsMenu.gameSettings.closed(%settingsMenu.configFile)
	%settingsMenu.configFile.save("user://config.ini")

func takeScreenshot() -> void:
	%screenshotViewportCont.visible = true
	%thumbnailTop.visible = false
	%thumbnailBottom.visible = false
	%screenshotViewport.size = Vector2(800,608)
	%screenshotInnerViewport.size = Vector2(800,608)
	%screenshotInnerCamera.position = levelStartCameraCenter()
	RenderingServer.canvas_item_clear(drawThumbnail)
	await get_tree().process_frame
	RenderingServer.force_draw()
	screenshot = %screenshotViewport.get_texture().get_image()
	screenshot.resize(200,152)
	%screenshotViewportCont.visible = false

func takeThumbnailScreenshot(withText:bool) -> void:
	%screenshotViewportCont.visible = true
	%thumbnailTop.visible = true
	%thumbnailBottom.visible = true
	%screenshotInnerViewport.size = Vector2(Game.levelBounds.size) if thumbnailEntireLevel else Vector2(800,608)
	%screenshotViewport.size = %screenshotInnerViewport.size + Vector2i(0,89)
	RenderingServer.canvas_item_clear(drawThumbnail)
	TextDraw.outlined(Game.FLEVELNAME,drawThumbnail,Game.level.name,Color.WHITE,Color.BLACK,36,Vector2(12,26))
	TextDraw.outlined(Game.FLEVELNAME,drawThumbnail,Game.level.author,Color.BLACK,Color.WHITE,36,Vector2(%screenshotInnerViewport.size.x-12,26),true)
	var nameWidth:float = Game.FLEVELNAME.get_string_size(Game.level.name,HORIZONTAL_ALIGNMENT_LEFT,-1,36).x
	Game.ROBOTO_MONO.draw_string(drawThumbnail,Vector2(30+nameWidth,41),"(Rev. %s)" % Game.level.revision,HORIZONTAL_ALIGNMENT_LEFT,-1,20)
	if Mods.activeModpack:%thumbnailModpack.texture = Mods.activeModpack.iconSmall
	%thumbnailModpack.visible = !!Mods.activeModpack
	%thumbnailMods.text = OpenWindow.textifyMods(Mods.getActiveMods(), Mods.activeModpack, Mods.activeVersion)
	%screenshotInnerCamera.position = Vector2(Game.levelBounds.position) if thumbnailEntireLevel else levelStartCameraCenter()
	if !thumbnailHideDescription and Game.level.description: PlayGame.drawLevelDescription(drawThumbnail,Vector2(0,64))
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw()
	var thumbnail:Image = (%screenshotViewport if withText else %screenshotInnerViewport).get_texture().get_image()
	%screenshotViewportCont.visible = false
	if OS.has_feature('web'):
		thumbnail.save_png("user://_thumbnail.png")
		JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes("user://_thumbnail.png"),"thumbnail.png")
	else: thumbnail.save_png("user://puzzles/_thumbnail.png")

func levelStartCameraCenter(screenSize:Vector2=Vector2(800,608)) -> Vector2:
	if Game.levelStart:
		@warning_ignore("narrowing_conversion") var levelBoundsInner:Rect2 = Game.levelBounds.grow_individual(-0.5*screenSize.x,-0.5*screenSize.y,-0.5*screenSize.x,-0.5*screenSize.y)
		return Game.levelStart.position.clamp(levelBoundsInner.position, levelBoundsInner.end) - screenSize/2
	return Vector2(Game.levelBounds.position) + (Vector2(Game.levelBounds.size) - screenSize)/2

func _gameViewportDisplayResized():
	var newSize:Vector2 = %gameViewportDisplay.size * Game.uiScale
	%gameViewport.size = newSize
	%placePreviewViewport.size = newSize
	RenderingServer.global_shader_parameter_set(&"SCREEN_SIZE", newSize)
