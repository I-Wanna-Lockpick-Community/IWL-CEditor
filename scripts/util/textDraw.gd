extends RefCounted
class_name TextDraw

static func outlined(font:Font,item:RID,string:String,color:Color,outlineColor:Color,fontSize:int,pos:Vector2=Vector2.ZERO,borderWidth:int=4) -> void:
	font.draw_string_outline(item,pos,string,HORIZONTAL_ALIGNMENT_LEFT,-1,fontSize,borderWidth,outlineColor)
	font.draw_string(item,pos,string,HORIZONTAL_ALIGNMENT_LEFT,-1,fontSize,color)

static func outlinedCentered(font:Font,item:RID,string:String,color:Color,outlineColor:Color,fontSize:int,pos:Vector2=Vector2.ZERO,borderWidth:int=4) -> void:
	var centerOffset:Vector2 = Vector2(font.get_string_size(string,HORIZONTAL_ALIGNMENT_LEFT,-1,fontSize).x/2,0)
	outlined(font,item,string,color,outlineColor,fontSize,pos-centerOffset,borderWidth)
