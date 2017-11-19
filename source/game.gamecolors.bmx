SuperStrict
Import "Dig/base.util.color.bmx"


Type TGameColorCollection
	Field basePalette:TGameColor[]
	Field extendedPalette:TGameColor[]
	'alternate this on each render
	global evenFrame:int = 0


	Method New()
		basePalette :+ [New TGameColor.Create(  0,  0,  0)]
		basePalette :+ [New TGameColor.Create(255,255,255)]
		basePalette :+ [New TGameColor.Create(136,  0,  0)]
		basePalette :+ [New TGameColor.Create(170,255,238)]
		basePalette :+ [New TGameColor.Create(204, 68,204)]
		basePalette :+ [New TGameColor.Create(  0,204, 85)]
		basePalette :+ [New TGameColor.Create(  0,  0,170)]
		basePalette :+ [New TGameColor.Create(238,238,119)]
		basePalette :+ [New TGameColor.Create(221,136, 85)]
		basePalette :+ [New TGameColor.Create(102, 68,  0)]
		basePalette :+ [New TGameColor.Create(255,119,119)]
		basePalette :+ [New TGameColor.Create( 51, 51, 51)]
		basePalette :+ [New TGameColor.Create(119,119,119)]
		basePalette :+ [New TGameColor.Create(170,255,102)]
		basePalette :+ [New TGameColor.Create(  0,136,255)]
		basePalette :+ [New TGameColor.Create(187,187,187)]

		For local colorIndex1:int = 0 until basePalette.length
			For local colorIndex2:int = colorIndex1 until basePalette.length
				local gColor:TGameColor = new TGameColor
				gColor.baseColor1 = basePalette[colorIndex1]
				gColor.baseColor2 = basePalette[colorIndex2]
				gColor.ActivateColor(1)
				extendedPalette :+ [gColor]
			Next
		Next
	End Method


	Method Update:int()
		evenFrame = 1 - evenFrame
		
		'inform our colors which base color they should use
		'for this render period
		For local gColor:TGameColor = EachIn extendedPalette
			gColor.ActivateColor(evenFrame + 1) '1 or 2
		Next
	End Method
End Type

Global GameColorCollection:TGameColorCollection = new TGameColorCollection




Type TGameColor extends TColor
	Field baseColor1:TColor
	Field baseColor2:TColor

	'override
	Function Create:TGameColor(r:int, g:int, b:int, a:Float=1.0)
		local col:TGameColor = new TGameColor
		col.InitRGBA(r, g, b, a)
		return col
	End Function


	'override
	Function CreateGrey:TGameColor(grey:int=0,a:float=1.0)
		local col:TGameColor = new TGameColor
		col.InitRGBA(grey, grey, grey, a)
		return col
	End Function
	

	'override
	Method Copy:TGameColor()
		local copyColor:TGameColor = new TGameColor
		copyColor.CopyFrom(self)
		if baseColor1 then copyColor.baseColor1 = baseColor1.Copy()
		if baseColor2 then copyColor.baseColor2 = baseColor2.Copy()
	End Method


	'override
	Method CopyFrom:TGameColor(color:TColor)
		if color
			self.r = color.r
			self.g = color.g
			self.b = color.b
			self.a = color.a
			if TGameColor(color)
				local gColor:TGameColor = TGameColor(color)
				if gcolor.baseColor1
					self.baseColor1 = gcolor.baseColor1.Copy()
				else
					self.baseColor1 = null
				endif
				if gcolor.baseColor2
					self.baseColor2 = gcolor.baseColor2.Copy()
				else
					self.baseColor2 = null
				endif
			endif
		endif
		return self
	End Method
	

	Method ActivateColor(colorNumber:int)
		if not baseColor1 then return
		
		if colorNumber = 1 or not baseColor2
			r = baseColor1.r
			g = baseColor1.g
			b = baseColor1.b
			a = baseColor1.a
		elseif colorNumber = 2
			r = baseColor2.r 
			g = baseColor2.g 
			b = baseColor2.b 
			a = baseColor2.a
		endif
	End Method
End Type