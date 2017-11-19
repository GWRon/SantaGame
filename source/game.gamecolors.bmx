SuperStrict
Import "Dig/base.util.color.bmx"


Type TGameColorCollection
	Field basePalette:TGameColor[]
	Field extendedPalette:TGameColor[]
	'alternate this on each render
	global evenFrame:int = 0
	global similarMode:int = 0
	Const SIMILAR_MODE_CIELAB:int = 0
	Const SIMILAR_MODE_EUCLIDEAN:int = 1


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
				if colorIndex1 <> colorIndex2
					gColor.baseColor1 = basePalette[colorIndex1]
					gColor.baseColor2 = basePalette[colorIndex2]
				endif
				gColor.ActivateColor(1)
				extendedPalette :+ [gColor]
			Next
		Next
	End Method


	'returns the most similar paletted color for a given rgb one
	Method FindSimilar:TGameColor(rgbColor:TColor)
		'check CACHE to avoid long calculations
		'TODO


		'find most similar color in the palettes

		'avoid calculating it over and over 
		local rgbColorL:float, rgbColorA:float, rgbColorB:float
		rgbColor.ToLAB(rgbColorL, rgbColorA, rgbColorB)

		local lowestDelta:Float = -1
		local lowestDeltaColor:TGameColor

		'loop over all palette colors
		if similarMode = SIMILAR_MODE_CIELAB
			for local gColor:TGameColor = EachIn extendedPalette
				local delta:Float = gColor.GetEffectiveColor().GetCIELABDelta_ByLAB(rgbColorL, rgbColorA, rgbColorB)
				if lowestDelta < 0 or delta < lowestDelta
					lowestDelta = delta
					lowestDeltaColor = gColor
				endif
			next
		elseif similarMode = SIMILAR_MODE_EUCLIDEAN
			for local gColor:TGameColor = EachIn extendedPalette
				local delta:Float = gColor.GetEffectiveColor().GetEuclideanDistance(rgbColor)

				if lowestDelta < 0 or delta < lowestDelta
					lowestDelta = delta
					lowestDeltaColor = gColor
				endif
			next
		endif

		print rgbColor.ToRGBString(",") + "  -   " + lowestDeltaColor.baseColor1.ToRGBString(",") +"/"+lowestDeltaColor.baseColor2.ToRGBString(",")  + " => " + lowestDeltaColor.GetEffectiveColor().ToRGBString(",") +" = " + lowestDelta 
		return lowestDeltaColor
	End Method


	'assigns new values to the given game color based on the given rgb color
	'-> "gameColor-reference" stays intact (no new variable created)
	Method MakeSimilar:int(gameColor:TGameColor, rgbColor:TColor)
		if not rgbColor then return False
		if not gameColor then gameColor = new TGameColor

		gameColor.CopyFrom( FindSimilar(rgbColor) )

		return True
	End Method


	'returns a paletted color for the given rgb color
	'-> new variable created
	Method CreateSimilar:TGameColor(rgbColor:TColor)
		if not rgbColor then return null

		local gColor:TGameColor = new TGameColor
		MakeSimilar(gColor, rgbColor)
		
		return gColor
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
	'base colors do not need to be of type "TGamecolor" as a mix of
	'two already "flickering" colors would lead to 4 colors alternating
	'which results in visible flickering
	Field baseColor1:TColor
	Field baseColor2:TColor
	'mix of both bases
	Field effectiveColor:TColor

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
		if effectiveColor then copyColor.effectiveColor = effectiveColor.Copy()
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
				if gcolor.effectiveColor
					self.effectiveColor = gcolor.effectiveColor.Copy()
				else
					self.effectiveColor = null
				endif
			endif
		endif
		return self
	End Method


	Method GetEffectiveColor:TColor()
		'only one color defined
		if not baseColor1 or not baseColor2 then return self

		'cache result if not done yet
		if not effectiveColor
			effectiveColor = new TColor.InitRGBA(0.5*(baseColor1.r+baseColor2.r), 0.5*(baseColor1.g+baseColor2.g), 0.5*(baseColor1.b+baseColor2.b), 1.0)
		endif
		return effectiveColor
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