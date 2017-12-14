Strict

Import "renderimage.bmx"

'SetGraphicsDriver GLMax2DDriver()
SetGraphicsDriver D3D9Max2DDriver()
'SetGraphicsDriver D3D11Max2DDriver()

Local gc:TGraphics = Graphics(800, 600, 32)
SetBlend AlphaBlend

Local rt:TRenderImage = CreateRenderImage(gc, 800, 600)
MidHandleImage(rt)

Local currentRotation:Int = 0
While Not KeyDown(KEY_ESCAPE)
	' render into the texture
	SetRenderImage(rt)
		SetRotation currentRotation
		SetScale 0.90, 0.90
		DrawImage(rt, GraphicsWidth()/2, GraphicsHeight()/2)
		currentRotation = (currentRotation + 5) Mod 360
		SetScale 1.0, 1.0

		SetRotation 0
		DrawOval(0,0, 10,10)

	' switch back to render to the original backbuffer
	SetRenderImage(Null)
	Cls
	SetColor 255,255,255
	DrawImage(rt, GraphicsWidth()/2, GraphicsHeight()/2)

	DrawText "Render 2 texture: " + GetGraphicsDriver().ToString(), 0, 0
	Flip
Wend
End
