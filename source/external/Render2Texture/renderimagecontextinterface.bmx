
Strict

Import "renderimageinterface.bmx"

Type TRenderimageContext
	Method Create:TRenderimageContext(context:TGraphics) Abstract
	Method Destroy() Abstract
	Method GraphicsContext:TGraphics() Abstract

	Method CreateRenderImage:TRenderImage(width:Int, height:Int, UseImageFiltering:Int) Abstract
	Method DestroyRenderImage(renderImage:TRenderImage) Abstract
	Method SetRenderImage(renderimage:TRenderImage) Abstract
	Method CreatePixmapFromRenderImage:TPixmap(renderImage:TRenderImage) Abstract
EndType
