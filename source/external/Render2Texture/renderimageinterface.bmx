
Strict

Import Brl.Max2D

Type TRenderImage Extends TImage
	Method CreateRenderImage:TRenderImage(width:Int, height:Int) Abstract
	Method DestroyRenderImage() Abstract
	Method SetRenderImage() Abstract
	Method SetViewport(x:Int, y:Int, width:Int, height:Int) Abstract
EndType
