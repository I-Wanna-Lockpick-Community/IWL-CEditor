extends MarginContainer
class_name ModTreeItem

const CHECKED:DPITexture = preload("res://resources/modTree/checked.tres")
const UNCHECKED:DPITexture = preload("res://resources/modTree/unchecked.tres")

const HOVERED_TEXT:Color = Color("#f2f2f2")
const UNHOVERED_TEXT:Color = Color("#b2b2b2")

var selectMods:SelectMods

var modId:StringName
var mod:Mods.Mod

@onready var button:Button = %button

func _ready() -> void:
	%label.text = mod.name
	%button.button_pressed = mod.active
	%disclosatory.visible = mod.disclosatory
	%undecided.visible = !!mod.undecided
	if mod.undecided: %undecided.tooltip_text = mod.undecided

func _toggled(toggled_on:bool) -> void:
	%icon.texture = CHECKED if toggled_on else UNCHECKED
	selectMods._modChanged(modId, toggled_on)

func _hover() -> void:
	%label.label_settings.font_color = HOVERED_TEXT
	selectMods._treeItemHovered(self)

func _unhover() -> void:
	%label.label_settings.font_color = UNHOVERED_TEXT
	selectMods._treeItemUnhovered(self)
