SuperStrict
Import "Dig/base.framework.graphicalapp.bmx"
Import "Dig/base.gfx.sprite.bmx"
Import "game.screens.game.bmx"
Import "game.screens.startscreen.bmx"
Import "game.screens.gameover.bmx"
Import "game.assets.bmx"
Import "game.gameconfig.bmx"



Type TMyApp Extends TGraphicalApp
	Method Prepare:Int()
		ApplyAppArguments()

		'load game configuration
		GameConfig.LoadFromFile("config/settings.xml")


		Local gm:TGraphicsManager = TGraphicsManager.GetInstance()
		gm.SetDesignedResolution(320, 200)

		if GameConfig.fullscreen then gm.SetFullscreen(True)
		if GameConfig.screenWidth > 0
			resolutionX = GameConfig.screenWidth
		else
			resolutionX = 320
		endif

		if GameConfig.screenHeight > 0
			resolutionY = GameConfig.screenHeight
		else
			resolutionY = 200
		endif
		

		Super.Prepare()

		'try to center the window, for now only Windows
		CenterAppWindow()
		'init loop
		GetDeltatimer().Init(30, -1, 60)

		'load assets
		GetAssets()

		'we use a full screen background - so no cls needed
		autoCls = False

		'=== CREATE SCREENS ===
		'GetScreenManager().Set(new TScreenMainMenu.Init("mainmenu"))
		GetScreenManager().Set(New TScreenInGame.Init("game"))
		GetScreenManager().Set(New TScreenGameOver.Init("gameover"))
		GetScreenManager().Set(New TStartScreen.Init("startscreen"))
		'set the active one
		'GetScreenManager().SetCurrent( GetScreenManager().Get("startscreen") )
		GetScreenManager().SetCurrent( GetScreenManager().Get("game") )
		GetScreenManager().SetExit(GetScreenManager().Get("startscreen"))

		GetScreenManager().Get("game").backScreenName = "startscreen"
	End Method


	Method ApplyAppArguments:Int()
		Local argNumber:Int = 0
		For Local arg:String = EachIn AppArgs
			'only interested in args starting with "-"
			If arg.Find("-") <> 0 Then Continue

			Select arg.ToLower()
				?Win32
				Case "-directx7", "-directx"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 7", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX7)
					GameConfig.renderer = GetGraphicsManager().RENDERER_DIRECTX7
				Case "-directx9"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 9", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX9)
					GameConfig.renderer = GetGraphicsManager().RENDERER_DIRECTX9
				Case "-directx11"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: DirectX 11", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_DIRECTX11)
					GameConfig.renderer = GetGraphicsManager().RENDERER_DIRECTX11
				?
				Case "-opengl"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: OpenGL", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_OPENGL)
					GameConfig.renderer = GetGraphicsManager().RENDERER_OPENGL
				Case "-bufferedopengl"
					TLogger.Log("TApp.ApplyAppArguments()", "Manual Override of renderer: Buffered OpenGL", LOG_LOADING)
					GetGraphicsManager().SetRenderer(GetGraphicsManager().RENDERER_BUFFEREDOPENGL)
					GameConfig.renderer = GetGraphicsManager().RENDERER_BUFFEREDOPENGL
			End Select
		Next
	End Method


	Function CenterAppWindow()
		'based on "ccCentreWindowHandle(hWnD%)" from the old blitzmax forums
		?Win32
		Local hWnd:int = GetActiveWindow()
		Local desk:int[4], window:int[4]
		GetWindowRect(GetDesktopWindow(), desk)
		GetWindowRect(hWnd, window)
	
		SetWindowPos(hWnd, HWND_NOTOPMOST, (desk[2] - (window[2] - window[1])) / 2, (desk[3] - (window[3] - window[0])) / 2, 0, 0, SWP_NOSIZE)	
		?
	End Function



	'override
	Function __UpdateInput:int()
		'needs modified "brl.mod/polledinput.mod" (disabling autopoll)
		SetAutoPoll(False)
		KEYMANAGER.Update()
		MOUSEMANAGER.Update()
		SetAutoPoll(True)
	End Function
	


	Method Update:Int()
'		Keymanager.Update()
'		Mousemanager.Update()
		'fetch and cache mouse and keyboard states for this cycle
		GUIManager.StartUpdates()

		'GetSoundManager().Update()

		'run parental update (screen handling)
		Super.Update()


		GUIManager.EndUpdates()
	End Method


	Method Render:Int()
		Super.Render()

		If KeyHit(KEY_F12) Then SaveScreenshot()
	End Method


	Method RenderContent:Int()
		'custom render content
	End Method


	Method RenderHUD:Int()
		'=== DRAW MOUSE CURSOR ===
		'...
	End Method

	'override
	Method ShutDown:Int()
		print "Storing configuration"
		GameConfig.SaveToFile("config/settings.xml")
	End Method


	Method SaveScreenshot(overlay:TSprite = Null)
		Local filename:String, padded:String
		Local num:Int = 1

		filename = "screenshot_001.png"

		While FileType(filename) <> 0
			num:+1

			padded = num
			While padded.length < 3
				padded = "0"+padded
			Wend
			filename = "screenshot_"+padded+".png"
		Wend

		Local img:TPixmap = VirtualGrabPixmap(0, 0, GraphicsWidth(), GraphicsHeight())

		'remove alpha
		SavePixmapPNG(ConvertPixmap(img, PF_RGB888), filename)

		TLogger.Log("App.SaveScreenshot", "Screenshot saved as ~q"+filename+"~q", LOG_INFO)
	End Method	
End Type
