SuperStrict
Framework Brl.StandardIO
Import "../source/game.gamecolors.bmx"
Import Brl.GLMax2d

SetGraphicsDriver GLMax2DDriver()
Graphics 640,400,0
SetVirtualResolution(320,200)

rem
'print out a color difference
print baseColorPalette[0].GetCIELABDelta(baseColorPalette[11])
print baseColorPalette[0].GetCIELABDelta(baseColorPalette[12])
print baseColorPalette[0].GetCIELABDelta(baseColorPalette[15])
print baseColorPalette[0].GetCIELABDelta(baseColorPalette[1])
endrem

Repeat
	Cls
	GameColorCollection.Update()

	For local i:int = 0 until GameColorCollection.extendedPalette.length
		GameColorCollection.extendedPalette[i].SetRGB()
		DrawText(i, 5 + (i / 13) * 28, 5 + (i mod 13)*15)
	Next

	Flip 1
Until AppTerminate() Or KeyHit(KEY_ESCAPE)

