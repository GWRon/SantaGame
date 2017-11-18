SuperStrict
Import "Dig/base.framework.graphicalapp.bmx"
Import "Dig/base.util.registry.bmx"
Import "Dig/base.util.registry.imageloader.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.sfx.soundmanager.bmx"

Import "game.bmx"



Type TScreenInGame extends TScreen
	Method Init:TScreenInGame(name:string)
		Super.Init(name)

		return self
	End Method


	'override
	Method PrepareStart:Int()
		'init game
		GetGame().Initialize()

'		GetGame().StartNewGame()
		GetGame().StartOldGame()

		return Super.PrepareStart()
	End Method


	'override
	Method RunAfterFadeIn:Int()
		return Super.RunAfterFadeIn()
	End Method

	

	Method Update:int()
		GameTime.Update()
rem
		If KeyManager.IsDown(KEY_1) and GetGame().currentLevel.GetReceiver(1) Then GetGame().currentLevel.GetReceiver(1).Finish()
		If KeyManager.IsDown(KEY_2) and GetGame().currentLevel.GetReceiver(2) Then GetGame().currentLevel.GetReceiver(2).Finish()
		If KeyManager.IsDown(KEY_3) and GetGame().currentLevel.GetReceiver(3) Then GetGame().currentLevel.GetReceiver(3).Finish()
		If KeyManager.IsDown(KEY_4) and GetGame().currentLevel.GetReceiver(4) Then GetGame().currentLevel.GetReceiver(4).Finish()
endrem		
		If KeyManager.IsHit(KEY_ESCAPE)
			KeyManager.ResetKey(KEY_ESCAPE)
			KeyManager.BlockKey(KEY_ESCAPE, 150)
			Back()
			'GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("startscreen") )
		endif
rem
		If KeyManager.IsHit(KEY_SPACE)
			print "manual game over"
			GetGame().currentLevel.AddTimeLeft( -1000 )
		endif
endrem

		GetGameBase().Update()

		if GetGameBase().IsGameOver()
			GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("gameover"), 0.0 )
		endif
		
rem
		If Not GetSoundManager().isPlaying()
			GetSoundManager().defaultMusicVolume = 0.3
			GetSoundManager().musicVolume = 0.3
			GetSoundManager().nextMusicVolume = 0.3

			GetSoundManager().PlayMusicPlaylist("default")
		endif
endrem
	End Method


	Method Render:int()
		Cls
		If GetAssets().bg Then GetAssets().bg.Draw(0, 0)

		GetGameBase().Render()

		RenderInterface()
	End Method


	'option 1 - write a function which can get overwritten itself too
	Method RenderInterface:Int()
		'store old color - so we do not have to care for alpha
		'of fading screens or other modificators
		local col:TColor = new TColor.Get()

		SetColor 255, 255, 255
		'GetAssets().mouseCursor.Draw(MouseManager.GetX() - 16, MouseManager.GetY() - 16, 1)
		DrawOval(MouseManager.GetX()-3, MouseManager.GetY()-3, 6, 6)

		col.SetRGBA()
	End Method


	'overwrite the function of TScreen - TGraphicalApp-Apps call this
	'automatically
	Method ExtraRender:int()
		'
	End Method

End Type