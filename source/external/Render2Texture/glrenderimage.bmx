
Strict

Import Pub.GLEW
Import BRL.GLMax2D
Import "renderimageinterface.bmx"

Type TGLRenderImageFrame Extends TGLImageFrame
	Field _fbo:Int
	
	Method Delete()
		DeleteFramebuffer
	EndMethod
	
	Method DeleteFramebuffer()
		If _fbo
			glDeleteFramebuffers(1, Varptr _fbo)
			_fbo = -1 '???
		EndIf
	EndMethod
	
	Method CreateRenderTarget:TGLRenderImageFrame(width, height, UseImageFiltering:Int)
		Local prevFBO:Int
		Local prevTexture:Int
		Local prevScissorTest:Int

		glGetIntegerv(GL_FRAMEBUFFER_BINDING, Varptr prevFBO)
		glGetIntegerv(GL_TEXTURE_BINDING_2D,Varptr prevTexture)
		glGetIntegerv(GL_SCISSOR_TEST, Varptr prevScissorTest)
		
		glDisable(GL_SCISSOR_TEST)

		glGenTextures 1, Varptr name
		glBindTexture GL_TEXTURE_2D,name
		glTexImage2D GL_TEXTURE_2D,0,GL_RGBA8,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,Null

		If UseImageFiltering
			glTexParameteri GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR
			glTexParameteri GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR
		Else
			glTexParameteri GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST
			glTexParameteri GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST
		EndIf
		
		glTexParameteri GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE
		glTexParameteri GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE
		
		glGenFramebuffers(1,Varptr _fbo)
		glBindFramebuffer GL_FRAMEBUFFER,_fbo

		glBindTexture GL_TEXTURE_2D,name
		glFramebufferTexture2D GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,name,0

		' set and clear to a default colour
		glClearColor 0, 0, 0, 0
		glClear(GL_COLOR_BUFFER_BIT)

		uscale = 1.0 / width
		vscale = 1.0 / height

		If prevScissorTest glEnable(GL_SCISSOR_TEST)
		glBindTexture GL_TEXTURE_2D,prevTexture
		glBindFramebuffer GL_FRAMEBUFFER,prevFBO

		Return Self
	EndMethod
	
	Method DestroyRenderTarget()
		DeleteFramebuffer()
	EndMethod
	
	Method ToPixmap:TPixmap(width:Int, height:Int)
		Local prevTexture:Int
		Local prevFBO:Int
		
		glGetIntegerv(GL_TEXTURE_BINDING_2D,Varptr prevTexture)
		glBindTexture(GL_TEXTURE_2D,name)

		Local pixmap:TPixmap = CreatePixmap(width, height, PF_RGBA8888)		
		glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixmap.pixels)
		
		glBindTexture(GL_TEXTURE_2D,prevTexture)
				
		Return pixmap
	EndMethod
EndType

Type TGLRenderImage Extends TRenderImage
	Field _matrix:Float[16]

	Method CreateRenderImage:TGLRenderImage(width:Int, height:Int)
		Self.width = width		' TImage.width
		Self.height = height	' TImage.height

		_matrix = [	2.0/width, 0.0, 0.0, 0.0,..
					0.0, 2.0/height, 0.0, 0.0,..
					0.0, 0.0, 1.0, 0.0,..
					-1-(1.0/width), -1-(1.0/height), 1.0, 1.0 ]

		Return Self
	EndMethod
	
	Method DestroyRenderImage()
		TGLRenderImageFrame(frames[0]).DestroyRenderTarget()
	EndMethod
	
	Method Init(UseImageFiltering:Int)
		frames = New TGLRenderImageFrame[1]
		frames[0] = New TGLRenderImageFrame.CreateRenderTarget(width, height, UseImageFiltering)
	EndMethod

	Method Frame:TImageFrame(index=0)
		Return frames[0]
	EndMethod
	
	Method SetRenderImage()
		glBindFrameBuffer(GL_FRAMEBUFFER, TGLRenderImageFrame(frames[0])._fbo)

		glMatrixMode(GL_PROJECTION)
		glLoadMatrixf(_matrix)
	
		glViewport 0,0,width,height 
	EndMethod
	
	Method ToPixmap:TPixmap()
		Return TGLRenderImageFrame(frames[0]).ToPixmap(width, height)
	EndMethod
	
	Method SetViewport(x:Int, y:Int, width:Int, height)
		If x = 0 And y = 0 And width = Self.width And height = Self.height
			glDisable GL_SCISSOR_TEST
		Else
			glEnable GL_SCISSOR_TEST
			glScissor x, y, width, height
		EndIf
	EndMethod
EndType





