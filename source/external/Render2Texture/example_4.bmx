SuperStrict

Import "renderimage.bmx"
SetGraphicsDriver glmax2dDriver()
Global gc:TGraphics = Graphics(800, 600)

SetVirtualResolution(1920, 1080)

Global renderImage:TRenderImage
Global setVirtualResolutionAgain:Int = False
Global lastChange:Int = MilliSecs()


Global bg:TImage = CreateImage(1920, 1080)
'create a checkerboard
Global pix:TPixmap = LockImage(bg)
Local cols:Int[] = [(Int(255 * $1000000) + Int(255 * $10000) + Int(255 * $100) + Int(255)), ..
                  (Int(255 * $1000000) + Int(255 * $10000) + Int(0 * $100) + Int(0))]
For Local x:Int = 0 Until 1920
	For Local y:Int = 0 Until 1080
		WritePixel(pix, x,y, cols[ ((Floor(x / 80) Mod 2 = 0) + (Floor(y / 80) Mod 2 = 0)) Mod 2 ])
	Next
Next

	


Function CreateRTImage:TRenderImage()
	Local rt:TRenderImage = CreateRenderImage(gc, 300, 300)
	SetRenderImage(rt)
	' render into the texture
	For Local i :Int = 0 To 100
		SetColor Rand(0,255), Rand(0,255), Rand(0,255)
		DrawText("Hey", Rand(0, rt.width-50), Rand(0, rt.height-20))
	Next

	SetRenderImage(Null)

	If setVirtualResolutionAgain Then SetVirtualResolution(1920, 1080)

	Return rt
End Function

While Not KeyDown(KEY_ESCAPE)	
	Cls
	
	SetColor 255,255,255
	If bg Then DrawImage(bg, 0, 0)
	
	If Not renderImage Then renderImage = CreateRTImage()
	If MilliSecs() - lastChange > 200
		If renderImage DestroyRenderImage(renderImage)
		renderImage = CreateRTImage()
		setVirtualResolutionAgain = 1 - setVirtualResolutionAgain
		lastChange = MilliSecs() + 200
	EndIf

	DrawImage(renderImage, 250, 250)
	
	DrawText("Virtual resolution", 50, 35)
	DrawText("Testing", 50, 50)
	Flip
Wend
