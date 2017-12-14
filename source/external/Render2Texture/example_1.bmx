
Strict
Framework Brl.StandardIO
Import "renderimage.bmx"

SetGraphicsDriver GLMax2DDriver()
Local gc:TGraphics = Graphics(800, 600)

Local rt:TRenderImage = CreateRenderImage(gc, 300, 150, False)
Local r2:TRenderImage = CreateRenderImage(gc, 300, 150)

SetClsColor 40, 80, 160

' render into the texture
SetRenderImage(rt)

Cls
For Local i :Int = 0 To 100
	SetColor Rand(0,255), Rand(0,255), Rand(0,255)
	DrawText("Hey", Rand(0, rt.width-50), Rand(0, rt.height-20))
Next

While Not KeyDown(KEY_ESCAPE)	
	' switch back to render to the original backbuffer
	SetRenderImage(Null)
	Cls
	SetColor 255,255,255
	SetScale 2,2
	DrawImage(rt,MouseX(),MouseY())
	
	'SetScale 1,1
	SetRenderImage(r2)
	DrawText "Render 2 texture: " + GetGraphicsDriver().ToString(), 0, 0
	
	SetRenderImage(Null)
	DrawImage(r2, GraphicsWidth() - MouseX(), GraphicsHeight() - MouseY())
	
	Flip
Wend
End

