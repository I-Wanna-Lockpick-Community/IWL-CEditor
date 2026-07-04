@tool
extends Node
class_name FileVersionGenerator

@export_tool_button("generate")
var c:Callable = _generate

enum EXPORT_GROUP {None, SavedProperties, SavedArrays, SavedComponentArrays}

func _generate() -> void:
	var fileVersion:FileVersion = FileVersion.new()
	fileVersion.version = Saving.FILE_FORMAT_VERSION
	fileVersion.firstEditorVersion = ProjectSettings.get_setting("application/config/version")
	fileVersion.componentTypes = Game.COMPONENTS
	var node2DPropertyNames:Array[String] = []
	var componentTypeNames:Array[String] = []
	node2DPropertyNames.assign(Node2D.new().get_property_list().map(func(property): return property.name))
	componentTypeNames.assign(Game.COMPONENTS.map(func(componentType): return componentType.get_global_name()))
	for componentType in Game.COMPONENTS:
		if Editor.scriptExtends(componentType, PlaceholderObject): continue
		var sample:GameComponent
		if componentType in Game.NON_OBJECT_COMPONENTS: sample = componentType.new()
		else: sample = componentType.SCENE.instantiate()
		var typeDef:ComponentTypeDef = ComponentTypeDef.new()
		var exportGroup:EXPORT_GROUP = EXPORT_GROUP.None
		for property in sample.get_property_list():
			if property.usage & PROPERTY_USAGE_GROUP or property.usage & PROPERTY_USAGE_CATEGORY:
				match property.name:
					"SavedProperties": exportGroup = EXPORT_GROUP.SavedProperties
					"SavedArrays": exportGroup = EXPORT_GROUP.SavedArrays
					"SavedComponentArrays": exportGroup = EXPORT_GROUP.SavedComponentArrays
					_: exportGroup = EXPORT_GROUP.None
			if property.name in node2DPropertyNames: continue
			if property.name.begins_with("metadata"): continue
			if exportGroup == EXPORT_GROUP.SavedProperties and (property.usage & PROPERTY_USAGE_STORAGE):
				typeDef.savedProperties.append(property.name)
			if property.type == TYPE_ARRAY:
				match exportGroup:
					EXPORT_GROUP.SavedArrays:
						typeDef.savedArrays.append(property.name)
					EXPORT_GROUP.SavedComponentArrays:
						var found:int = componentTypeNames.find(property.hint_string.split(":")[1])
						if found != -1: typeDef.savedComponentArrays[property.name] = Game.COMPONENTS[found]
						else: push_error("SavedComponentArray %s.%s doesn't contain a type of component" % [componentType.get_global_name(), property.name])
		typeDef.savedProperties.append(&"position")
		fileVersion.typeDefs[componentType] = typeDef
	var path:String = Saving.FILE_VERSIONS_PATH+str(fileVersion.version)+".tres"
	fileVersion.take_over_path(path)
	ResourceSaver.save(fileVersion)
	EditorInterface.call_deferred(&"edit_resource", fileVersion)
