SuperStrict
Import "Dig/base.framework.graphicalapp.bmx"
Import "Dig/base.util.registry.bmx"
Import "Dig/base.util.registry.imageloader.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.sfx.soundmanager.bmx"

Import "game.bmx"



Type TScreenGameOver extends TScreen
	Field gameOverAnimStart:Long = 0
	Field gameOverAnimTime:Int = 1500
	Field gameOverScale:Float = 0.0


	Method Init:TScreenGameOver(name:string)
		Super.Init(name)

		return self
	End Method


	'override
	Method PrepareStart:Int()
		gameOverAnimStart = 0
		gameOverAnimTime = 1500
		gameOverScale = 0.0


		'gui

		return Super.PrepareStart()
	End Method

	

	Method Update:int()
		If KeyManager.IsHit(KEY_ESCAPE)
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 150)
			'Back()
			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("startscreen") )
		endif
			
		If Not GetSoundManager().isPlaying()
			GetSoundManager().defaultMusicVolume = 0.3
			GetSoundManager().musicVolume = 0.3
			GetSoundManager().nextMusicVolume = 0.3

			GetSoundManager().PlayMusicPlaylist("default")
		endif
	End Method


	Method Render:int()
		Cls
		If GetAssets().bg Then GetAssets().bg.Draw(0, 0)

		'render in background
		GetGameBase().Render()

		SetAlpha 0.6
		SetColor 0,0,0
		DrawRect(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		SetColor 255,255,255
		SetAlpha 1.0

		If GetAssets().gameOver
			Local timeGone:Int = Time.GetTimeGone()
			If gameOverAnimStart = 0 Then gameOverAnimStart = timeGone
			gameOverScale = TInterpolation.ElasticOut(0.0, 1.0, Min(gameOverAnimTime, timeGone - gameOverAnimStart), gameOverAnimTime)
			gameOverScale :* TInterpolation.BounceOut(0.0, 1.0, Min(gameOverAnimTime, timeGone - gameOverAnimStart), gameOverAnimTime)

			GetAssets().gameOver.Draw( GetGraphicsManager().GetWidth()/2, GetGraphicsManager().GetHeight()/2, -1, ALIGN_CENTER_CENTER, gameOverScale)
		endif

		GetBitmapFont("default", 10).DrawBlock("Hit ESCAPE to return to main menu", GetGraphicsManager().GetWidth()/2 - 100, GetGraphicsManager().GetHeight()/2 + 50, 200,50, ALIGN_CENTER_CENTER)
		
		RenderInterface()
	End Method


	'option 1 - write a function which can get overwritten itself too
	Method RenderInterface:Int()
		'store old color - so we do not have to care for alpha
		'of fading screens or other modificators
		local col:TColor = new TColor.Get()

		SetColor 255, 255, 255
'		GetAssets().mouseCursor.Draw(MouseManager.GetX() - 16, MouseManager.GetY() - 16, 1)

		col.SetRGBA()
	End Method


	'overwrite the function of TScreen - TGraphicalApp-Apps call this
	'automatically
	Method ExtraRender:int()
		'
	End Method

End Type