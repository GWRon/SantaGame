SuperStrict
Framework Brl.StandardIO
Import "../source/game.gamecolors.bmx"
Import Brl.GLMax2d

SetGraphicsDriver GLMax2DDriver()
Graphics 640,400,0
SetVirtualResolution(320,200)


'local myColor:TColor = new TColor.InitRGBA(Rand(255), Rand(255), Rand(255))
local myColor:TColor = new TColor.InitRGBA(93, 161, 221)
local gameColor:TGameColor = GameColorCollection.FindSimilar(myColor)

Repeat
	Cls
	GameColorCollection.Update()

	if KeyHit(KEY_SPACE) or MouseHit(1)
		myColor.InitRGBA(Rand(255), Rand(255), Rand(255))
		gameColor = GameColorCollection.FindSimilar(myColor)
	endif 
	if KeyHit(KEY_UP) or MouseHit(3)
		myColor.AdjustBrightness(0.1)
		gameColor = GameColorCollection.FindSimilar(myColor)
	endif 
	if KeyHit(KEY_Down) or MouseHit(2)
		myColor.AdjustBrightness(-0.1)
		gameColor = GameColorCollection.FindSimilar(myColor)
	endif
	if KeyHit(KEY_S)
		GameColorCollection.SetSimilarityAlgorithm(1 - GameColorCollection._similarityAlgorithm)
		gameColor = GameColorCollection.FindSimilar(myColor)
	endif
	

	myColor.SetRGB()
	DrawRect(5,20,100,100)

	gameColor.SetRGB()
	DrawRect(110,20,100,100)

	gameColor.GetEffectiveColor().SetRGB()
	DrawRect(215,20,100,100)

	SetColor 0,0,0
	DrawText(myColor.ToRGBString(","), 10,60)
	if gameColor.baseColor1 then DrawText(gameColor.baseColor1.ToRGBString(","), 115,60)
	if gameColor.baseColor2 then DrawText(gameColor.baseColor2.ToRGBString(","), 115,78)
	DrawText(gameColor.GetEffectiveColor().ToRGBString(","), 220,60)
	SetColor 255,255,255

	SetColor 255,255,255
	DrawText("RGB:", 10,2)
	DrawText("Paletted:", 115,2)
	DrawText("NonFlicker:", 220,2)

	DrawText("[SPACE] or [LMB] for new color", 10,125)
	DrawText("[UP] or [MMB] to increase brightness", 10,143)
	DrawText("[DOWN] or [RMB] to decrease brightness", 10,161)
	if GameColorCollection._similarityAlgorithm = TGameColorCollection.SIMILAR_MODE_EUCLIDEAN
		DrawText("[S] Similar mode: Euclidean -> CIELab", 10,179)
	else
		DrawText("[S] Similar mode: CIELab -> Euclidean", 10,179)
	endif
	Flip 1
Until AppTerminate() Or KeyHit(KEY_ESCAPE)

