
Strict
Framework Brl.StandardIO
Import "renderimage.bmx"

SetGraphicsDriver D3D9Max2DDriver()
Local gc:TGraphics = Graphics(800, 600, 32)
Local rt:TRenderImage = CreateRenderImage(gc, 300, 150)


' render into the texture
SetRenderImage(rt)
SetClsColor 40, 80, 160
Cls
For Local i :Int = 0 To 100
	SetColor Rand(0,255), Rand(0,255), Rand(0,255)
	DrawText("Hey", Rand(0, rt.width-50), Rand(0, rt.height-20))
Next
SetRenderImage(Null)

' grab a pixmap of the rendered texture
Local pixmap:TPixmap = CreatePixmapFromRenderImage(rt)

SetColor 255,255,255
While Not KeyDown(KEY_ESCAPE)	
	Cls

	DrawPixmap(pixmap, 60, 60)

	Flip
Wend
End

