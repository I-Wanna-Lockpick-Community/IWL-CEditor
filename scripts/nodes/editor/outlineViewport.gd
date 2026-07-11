extends TextureRect
class_name OutlineViewport

# displays three "outline channels"
# draw red green or blue shapes on this, and outlines of them will be displayed with the width of the shader parameter
# each color channel creates an outline of the corresponding color given by the shader parameters
# r covers g covers b
# remember to make the shadermaterial unique

func createChild() -> RID:
	var canvasItem:RID = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(canvasItem, %parent.get_canvas_item())
	RenderingServer.canvas_item_set_material(canvasItem, Game.ADDITIVE_FLAT_COLOR_MATERIAL)
	return canvasItem

func _process(_delta) -> void:
	%camera.position = Game.editor.editorCamera.position
	%camera.zoom = Game.editor.editorCamera.zoom


func _resized():
	%viewport.size = size * Game.uiScale
