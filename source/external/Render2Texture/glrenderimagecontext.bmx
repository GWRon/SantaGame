
Strict

Import "renderimagecontextinterface.bmx"
Import "glrenderimage.bmx"

Global glewIsInit:Int

Type TGLRenderImageContext Extends TRenderImageContext
	Field _gc:TGLGraphics
	Field _backbuffer:Int
	Field _width:Int
	Field _height:Int
	Field _renderimages:TList
	
	Field _matrix:Float[16]

	Method Delete()
		Destroy()
	EndMethod

	Method Destroy()
		_gc = Null
		If _renderimages
			For Local ri:TGLRenderImage = EachIn _renderimages
				ri.DestroyRenderImage()
			Next
		EndIf
	EndMethod

	Method Create:TGLRenderimageContext(context:TGraphics)
		If Not glewIsInit
			glewInit
			glewIsInit = True
		EndIf

		_renderimages = New TList
		_gc = TGLGraphics(context)
		_width = GraphicsWidth()
		_height = GraphicsHeight()

		' get the backbuffer - usually 0
		glGetIntegerv(GL_FRAMEBUFFER_BINDING, Varptr _backbuffer)
		
		glGetFloatv(GL_PROJECTION_MATRIX, _matrix)
		
		Return Self
	EndMethod

	Method GraphicsContext:TGraphics()
		Return _gc
	EndMethod

	Method CreateRenderImage:TRenderImage(width:Int, height:Int, UseImageFiltering:Int)
		Local renderimage:TGLRenderImage = New TGLRenderImage.CreateRenderImage(width, height)
		renderimage.Init(UseImageFiltering)
		Return  renderimage
	EndMethod
	
	Method DestroyRenderImage(renderImage:TRenderImage)
		renderImage.DestroyRenderImage()
		_renderImages.Remove(renderImage)
	EndMethod

	Method SetRenderImage(renderimage:TRenderimage)
		If Not renderimage
			glBindFramebuffer(GL_FRAMEBUFFER,_backbuffer)
		
			glMatrixMode(GL_PROJECTION)
			glLoadMatrixf(_matrix)
			
			glViewport(0,0,_width,_height)
		Else
			renderimage.SetRenderImage()
		EndIf
	EndMethod
	
	Method CreatePixmapFromRenderImage:TPixmap(renderImage:TRenderImage)
		Return TGLRenderImage(renderImage).ToPixmap()
	EndMethod
EndType
