SuperStrict
Framework Brl.StandardIO
Import "../source/game.gamecolors.bmx"
Import "../source/Dig/base.util.helper.bmx"
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
'52:  3,10   170,255,238 / 255,119,119
'65:  4,11   204,68,204 / 51,51,51
'78:  5,13   0,204,85 / 170,255,102
local enabledKey:string = "52,65,78,79,80,91,104,105,106"
local disabledKey:string = ""

local enabledColors:int[] = new Int[GameColorCollection.extendedPalette.length]
local disabledColors:int[] = new Int[GameColorCollection.extendedPalette.length]
if enabledKey = ""
	for local i:int = 0 until enabledColors.length
		enabledColors[i] = 1
	next
else
	local keys:string[] = enabledKey.split(",")
	for local i:int = 0 until keys.length
		if int(keys[i]) >= enabledcolors.length or int(keys[i]) < 0 then continue
		
		enabledColors[int(keys[i])] = 1
	next
endif
if disabledKey = ""
	for local i:int = 0 until disabledColors.length
		disabledColors[i] = 0
	next
else
	local keys:string[] = disabledKey.split(",")
	for local i:int = 0 until keys.length
		if int(keys[i]) >= disabledColors.length or int(keys[i]) < 0 then continue
		
		disabledColors[int(keys[i])] = 1
	next
endif


Repeat
	Cls
	GameColorCollection.Update()

	If MouseHit(1)
		For local i:int = 0 until GameColorCollection.extendedPalette.length
			if THelper.IsIn(VirtualMouseX(), VirtualMouseY(), 5 + (i / 13) * 28, 5 + (i mod 13)*15, 28, 15)
				enabledColors[i] = 1 - enabledColors[i]
				disabledColors[i] = 0
			endif
		Next
	endif
	If MouseHit(2)
		For local i:int = 0 until GameColorCollection.extendedPalette.length
			if THelper.IsIn(VirtualMouseX(), VirtualMouseY(), 5 + (i / 13) * 28, 5 + (i mod 13)*15, 28, 15)
				disabledColors[i] = 1 - disabledColors[i]
				enabledColors[i] = 0
			endif
		Next
	endif

	If KeyHit(KEY_SPACE)
		local enabledKeys:string[]
		local disabledKeys:string[]
		print "-------------"
		For local i:int = 0 until GameColorCollection.extendedPalette.length
			if enabledColors[i]
				if GameColorCollection.extendedPalette[i].GetBaseColor(1).ToInt() <> GameColorCollection.extendedPalette[i].GetBaseColor(2).ToInt()
					print RSet(i,3)+": " + GameColorCollection.extendedPalette[i].GetBaseColor(1).ToRGBString() + " / " + GameColorCollection.extendedPalette[i].GetBaseColor(2).ToRGBString()
				else
					print RSet(i,3)+": " + GameColorCollection.extendedPalette[i].GetBaseColor(1).ToRGBString() + " / " + GameColorCollection.extendedPalette[i].GetBaseColor(2).ToRGBString()
				endif
				enabledKeys :+ [string(i)]
			endif
			if disabledColors[i]
				disabledKeys :+ [string(i)]
			endif
		Next
		print "enabled:"
		print ",".join(enabledKeys)
		print "disabled:"
		print ",".join(disabledKeys)
		print "--------------"
	EndIf

	For local i:int = 0 until GameColorCollection.extendedPalette.length
		GameColorCollection.extendedPalette[i].SetRGB()
		DrawText(i, 5 + (i / 13) * 28, 5 + (i mod 13)*15)
		if enabledColors[i]
			SetColor 0,255,0
		elseif disabledColors[i]
			SetColor 255,0,0
		else
			continue
		endif
		DrawRect(5 + (i / 13) * 28 -1, 5 + (i mod 13)*15, 25, 1)
		DrawRect(5 + (i / 13) * 28 -1, 5 + (i mod 13)*15 + 14, 25, 1)
		DrawRect(5 + (i / 13) * 28 -1, 5 + (i mod 13)*15, 1, 15)
		DrawRect(5 + (i / 13) * 28 + 25 -1, 5 + (i mod 13)*15, 1, 15)
	Next

	Flip 1
Until AppTerminate() Or KeyHit(KEY_ESCAPE)

