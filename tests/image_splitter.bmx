SuperStrict
Framework Brl.StandardIO
Import "../source/game.gamecolors.bmx"
Import "../source/game.gamesprite.bmx"
Import Brl.GLMax2d

SetGraphicsDriver GLMax2DDriver()
Graphics 640,400,0
SetVirtualResolution(320,200)


local img:TImage = LoadImage("../assets/gfx/entity_player.png", DYNAMICIMAGE)
local img2:TImage
local img3:TImage
CreatePalettedImages(img, img2, img3)


Repeat
	Cls
	GameColorCollection.Update()

	SetColor 120,120,120
	DrawRect(5,5,74,74)
	DrawRect(85,5,74,74)
	DrawRect(165,5,74,74)
	DrawRect(85+40,5+80,74,74)
	SetColor 255,255,255
	DrawImage(img, 10,10)
	if img2 then DrawImage(img2, 90,10)
	if img3 then DrawImage(img3, 170,10)

	if img2 and GameColorCollection.evenFrame then DrawImage(img2, 90+40,10+80)
	if img3 and not GameColorCollection.evenFrame then DrawImage(img3, 90+40,10+80)
	

	Flip 1
Until AppTerminate() Or KeyHit(KEY_ESCAPE)

