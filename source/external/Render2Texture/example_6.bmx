SuperStrict

Framework brl.glmax2d
Import brl.standardio
Import "renderimage.bmx"

Global g:TGraphics = Graphics(640, 400, 0)
Global renderImage:TRenderImage = CreateRenderImage(g, 320, 200)

While Not KeyDown(key_escape)
	Cls

	SetRenderImage(renderImage)
		Cls
		Local vpX:Int, vpY:Int, vpH:Int, vpW:Int
		GetViewport(vpX, vpY, vpW, vpH)
		'print "vpX="+vpX+"  vpY="+vpY+"  vpH="+vpH+"  vpW="+vpW
		renderImage.SetViewport(70, 0, 184, 190)
		SetColor 0,0,250
		DrawRect(70,0,184,190)
		SetColor 255,255,255
		SetViewport(vpX, vpY, vpW, vpH)
	SetRenderImage(Null)

	If renderImage
		SetScale 2,2
		DrawImage(renderImage,0,0)
		SetScale 1,1
	EndIf

	Flip 1
Wend