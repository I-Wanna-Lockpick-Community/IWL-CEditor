class_name PencilmarkDialog
extends SubDialog

func _ready() -> void:
	%weirdButtons.visible = !Game.editor

func focus(focused:Pencilmark, new:bool, _dontRedirect:bool) -> void:
	%pencilmarkColorSelector.setSelect(focused.color)
	%pencilmarkTypeSelector.setSelect(focused.type)
	%pencilmarkSymbolSelector.setSelect(focused.symbol)
	%pencilmarkSymbolSelector.visible = focused.type == Pencilmark.TYPE.SYMBOL
	%pencilmarkNumberEdit.visible = focused.type == Pencilmark.TYPE.NUMBER
	%pencilmarkTextEdit.visible = focused.type == Pencilmark.TYPE.TEXT
	if new:
		%pencilmarkNumberEdit.setValue(focused.number)
		%pencilmarkTextEdit.text = focused.text

func receiveKey(_event:InputEventKey) -> bool:
	return false

func _pencilmarkColorSelected(color:C.olors) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"color",color))
	Changes.bufferSave()

func _pencilmarkTypeSelected(type:Pencilmark.TYPE) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"type",type))
	Changes.bufferSave()

func _pencilmarkSymbolSet(symbol:Pencilmark.SYMBOL) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"symbol",symbol))
	Changes.bufferSave()

func _pencilmarkNumberSet(value:PackedInt64Array) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"number",value))
	Changes.bufferSave()

func _pencilmarkTextSet(value:String) -> void:
	if main.focused is not Pencilmark: return
	Changes.addChange(Changes.PropertyChange.new(main.focused,&"text",value))
	Changes.bufferSave()
