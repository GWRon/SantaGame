SuperStrict
Import "Dig/base.framework.graphicalapp.bmx"
Import "Dig/base.util.registry.bmx"
Import "Dig/base.util.registry.imageloader.bmx"
Import "Dig/base.util.interpolation.bmx"
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.sfx.soundmanager.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "game.assets.bmx"
Import "game.gameconfig.bmx"
Import "game.gamecolors.bmx"



Type TStartScreen extends TScreen
	Field guiButtonStart:TGUIButton
	Field guiButtonProfile:TGUIButton
	Field guiButtonDoubleWindow:TGUIButton
	Field guiButtonNormalWindow:TGUIButton
	Field guiButtonQuit:TGUIButton
	Field stateName:TLowerString

	Field logoAnimStart:Int = 0
	Field logoAnimTime:Int = 1500
	Field logoScale:Float = 0.0



	Method Init:TStartScreen(name:string)
		Super.Init(name)

		stateName = TLowerString.Create(name)

		return self
	End Method


	'override
	Method PrepareStart:Int()
		logoAnimStart = 0
		logoAnimTime = 1500
		logoScale = 0.0


		'initialize gui stuff if not done
		if not guiButtonStart
			local buttonWidth:int = 160
			local buttonStartX:int = 0.5 * (GetGraphicsManager().GetWidth()-buttonWidth)
			local buttonStartY:int = 70
			TGUIButton.SetTypeFont( GetBitmapFont("default", 8) )
			TGUIButton.SetTypeCaptionColor( TColor.CreateGrey(51) )

			guiButtonStart   = New TGUIButton.Create(New TVec2D.Init(buttonStartX, buttonStartY + 0*24), New TVec2D.Init(buttonWidth, 20), "Start Game", name)
			guiButtonProfile = New TGUIButton.Create(New TVec2D.Init(buttonStartX, buttonStartY + 1*24), New TVec2D.Init(buttonWidth, 20), "New Player Profile", name)
			guiButtonNormalWindow = New TGUIButton.Create(New TVec2D.Init(buttonStartX, buttonStartY + 2.5*24), New TVec2D.Init(buttonWidth/2 -10, 20), "Normal Window", name)
			guiButtonDoubleWindow = New TGUIButton.Create(New TVec2D.Init(buttonStartX + buttonWidth/2 + 10, buttonStartY + 2.5*24), New TVec2D.Init(buttonWidth/2 -10, 20), "Double Window", name)
			guiButtonQuit    = New TGUIButton.Create(New TVec2D.Init(buttonStartX, buttonStartY + 4*24), New TVec2D.Init(buttonWidth, 20), "Exit", name)

			EventManager.registerListenerMethod("guiobject.onClick", Self, "onClickButtons")
		endif

		return Super.PrepareStart()
	End Method



	'handle clicks on the buttons
	Method onClickButtons:Int(triggerEvent:TEventBase)
		Local sender:TGUIButton = TGUIButton(triggerEvent._sender)
		If Not sender Then Return False

		Select sender
			Case guiButtonStart
				GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("game") )

			Case guiButtonProfile
				GameConfig.playerProfile = new TPlayerProfile.Initialize()
				'GetScreenManager().GetCurrent().FadeToScreen( GetScreenManager().Get("game") )

			Case guiButtonDoubleWindow
				GetGraphicsManager().SetResolution(640, 400)
				GetGraphicsManager().InitGraphics()
			Case guiButtonNormalWindow
				GetGraphicsManager().SetResolution(320, 200)
				GetGraphicsManager().InitGraphics()

			Case guiButtonQuit
				TApp._instance.exitApp = True
		End Select
	End Method
		

	Method Update:int()
		if GameConfig.GetPlayerProfile().currentLevelNumber > 1
			guiButtonStart.SetValue("Continue Game")
		else
			guiButtonStart.SetValue("Start New Game")
		endif

		rem
		If Not GetSoundManager().isPlaying()
			GetSoundManager().defaultMusicVolume = 0.3
			GetSoundManager().musicVolume = 0.3
			GetSoundManager().nextMusicVolume = 0.3

			GetSoundManager().PlayMusicPlaylist("default")
		endif
		endrem

		If KeyManager.IsDown(KEY_ESCAPE) Then TApp._instance.exitApp = True

		GUIManager.Update(stateName)
	End Method


	Method Render:int()
		local oldCol:TColor = new TColor.get()

		Cls
		If GetAssets().bgStartScreen Then GetAssets().bgStartScreen.Draw(0, 0)
		If GetAssets().logo
			Local timeGone:Int = Time.GetTimeGone()
			If logoAnimStart = 0 Then logoAnimStart = timeGone
			logoScale = TInterpolation.BackOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)
			logoScale :* TInterpolation.BounceOut(0.0, 1.0, Min(logoAnimTime, timeGone - logoAnimStart), logoAnimTime)

			GetAssets().logo.Draw( GetGraphicsManager().GetWidth()/2, GetGraphicsManager().GetHeight()/2, -1, ALIGN_CENTER_CENTER, logoScale)
		endif

		GetBitmapFont("default", 10).Draw("|color="+GameColorCollection.basePalette[5].ToRGBString(",")+"|v0.0nothing|/color|", 20, GetGraphicsManager().GetHeight()-40)
		
		GUIManager.Draw(stateName)

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