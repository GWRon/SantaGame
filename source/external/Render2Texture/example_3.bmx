
Strict

Import "renderimage.bmx"

Global gGraphicsDriver:TGraphicsDriver
Global gGraphics:TGraphics
Global gRenderImage:TRenderImage

SetGraphicsDriver GLMax2DDriver()
gGraphicsDriver = GetGraphicsDriver()
gGraphics = Graphics(800, 600)
InitResources()

While Not KeyDown(KEY_ESCAPE)
?win32
	If KeyDown(KEY_G)
		ChangeDriver()
		InitResources()
	EndIf
?
	
	' switch back to render to the original backbuffer
	SetRenderImage(Null)
	Cls
	SetColor 255, 255, 255
	
	DrawImage(gRenderImage,MouseX(),MouseY())
	DrawText("Render 2 texture: " + GetGraphicsDriver().ToString(), 0, 0)
	Flip
Wend
End

Function InitResources()
	gRenderImage = CreateRenderImage(gGraphics, 300, 150)
	SetClsColor(40, 80, 160)
	
	' render into the texture
	SetRenderImage(gRenderImage)

	Cls
	For Local i :Int = 0 To 100
		SetColor(Rand(0, 255), Rand(0, 255), Rand(0, 255))
		DrawText("Hey", Rand(0, gRenderImage.width-50), Rand(0, gRenderImage.height-20))
	Next
EndFunction

?win32
Function ChangeDriver()
	If TGLMax2DDriver(gGraphicsDriver)
		gGraphicsDriver = D3D9Max2DDriver()
	
	ElseIf TD3D9Max2DDriver(gGraphicsDriver)
		gGraphicsDriver = D3D11Max2DDriver()
	
	ElseIf TD3D11Max2DDriver(gGraphicsDriver)
		gGraphicsDriver = GLMax2DDriver()
		
	EndIf
	
	SetGraphicsDriver(gGraphicsDriver)
	gGraphics = Graphics(800, 600, 32)
EndFunction
?








