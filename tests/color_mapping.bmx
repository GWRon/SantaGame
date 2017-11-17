SuperStrict
Framework Brl.StandardIO
Import "../source/external/Dig/base.util.color.bmx"
Import Brl.GLMax2d

SetGraphicsDriver GLMax2DDriver()
Graphics 640,400,0
SetVirtualResolution(320,200)



Local baseColorPalette:TColor[]
baseColorPalette :+ [New TColor.Create(  0,  0,  0)]
baseColorPalette :+ [New TColor.Create(255,255,255)]
baseColorPalette :+ [New TColor.Create(136,  0,  0)]
baseColorPalette :+ [New TColor.Create(170,255,238)]
baseColorPalette :+ [New TColor.Create(204, 68,204)]
baseColorPalette :+ [New TColor.Create(  0,204, 85)]
baseColorPalette :+ [New TColor.Create(  0,  0,170)]
baseColorPalette :+ [New TColor.Create(238,238,119)]
baseColorPalette :+ [New TColor.Create(221,136, 85)]
baseColorPalette :+ [New TColor.Create(102, 68,  0)]
baseColorPalette :+ [New TColor.Create(255,119,119)]
baseColorPalette :+ [New TColor.Create( 51, 51, 51)]
baseColorPalette :+ [New TColor.Create(119,119,119)]
baseColorPalette :+ [New TColor.Create(170,255,102)]
baseColorPalette :+ [New TColor.Create(  0,136,255)]
baseColorPalette :+ [New TColor.Create(187,187,187)]


print baseColorPalette[0].GetCIELABDelta(baseColorPalette[11])
print baseColorPalette[0].GetCIELABDelta(baseColorPalette[12])
print baseColorPalette[0].GetCIELABDelta(baseColorPalette[15])
print baseColorPalette[0].GetCIELABDelta(baseColorPalette[1])

Repeat
	Cls
	Flip 0
Until AppTerminate() Or KeyHit(KEY_ESCAPE)

