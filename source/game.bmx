SuperStrict
Import Brl.Max2D
Import Brl.PNGLoader
Import "Dig/base.util.graphicsmanager.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "Dig/base.util.time.bmx"
Import "Dig/base.util.interpolation.bmx"
'Import "external/Render2Texture/renderimage.bmx"
Import "game.base.bmx"
Import "game.gamelevel.bmx"
Import "game.gameentity.text.bmx"
Import "game.gameconfig.bmx"
Import "game.playerprofile.bmx"



Type TGame Extends TGameBase
	Field levelTimer:int = 120
	'different steps of a level: level-start-introduction, the level itself,...
	Field levelStartStepTime:Long = -1
	Field levelStartStep:int = 0
	Field lastLevelTimerSecond:Long = -1

	Field currentLevel:TGameLevel
	'entities to update/render regardless of level
	Field activeHudEntities:TList = CreateList()
	Field activeScoreEntities:TList = CreateList()

	'Field currentLevel:TGameLevel
	Field initialized:int = False
	'active profile
	Field playerProfile:TPlayerProfile
	Field introductionsToShow:TList = CreateList()

	CONST STARTSTEP_NONE:int = 0
	CONST STARTSTEP_INTRODUCTION:int = 1
	CONST STARTSTEP_START:int = 2
	CONST STARTSTEP_STARTED:int = 3


	Function GetInstance:TGame()
		If Not TGame(_instance)
			'TODO
			If TGameBase(_instance)
				_instance = New TGame.InitializeFromBase(_instance)
			Else
				_instance = New TGame.Initialize()
			EndIf
		EndIf
		
		Return TGame(_instance)
	End Function


	Method Initialize:TGame()
		if initialized then return self

		'initialize elements here

		initialized = true

		Return Self
	End Method


	Method InitializeFromBase:TGame(base:TGameBase)
		'THelper.TakeOverObjectValues(base, self)

		Initialize()

		Return Self
	End Method


	Method StartNewGame:int()
		GameConfig.GetPlayerProfile().currentLevelNumber = 1
		currentLevel = GetLevel(1)

		SetLevelStartStep(STARTSTEP_NONE)
	End Method


	Method StartOldGame:int()
		GameConfig.GetPlayerProfile().currentLevelNumber = Max(1, GameConfig.GetPlayerProfile().currentLevelNumber)
		currentLevel = GetLevel(GameConfig.GetPlayerProfile().currentLevelNumber)

		SetLevelStartStep(STARTSTEP_NONE)
	End Method


	Function GetLevel:TGameLevel(levelNumber:int)
		'TODO: generate them via xml or so
		local gameLevel:TGameLevel = new TGameLevel
		gameLevel.name = "Level " + levelNumber
		gameLevel.TimeForLevel = 120
		'...

		return gameLevel
	End Function


	Method PrepareLevel()
		if not currentLevel then throw "Game.PrepareCurrentLevel: Cannot prepare level"

		'remove old particles
		'remove old scores floating on screen
		'... clear filled lists

		introductionsToShow.Clear()
		currentLevel.Reset()

		if GameConfig.GetPlayerProfile().currentLevelNumber = 1
			introductionsToShow.AddLast("welcome")
		endif

		'add other introductions to show - depending on the level
	End Method


	Method StartLevel()
		print "Game.StartLevel: " + GameConfig.GetPlayerProfile().currentLevelNumber

		currentLevel.Reset()
		currentLevel.Start()

		onStartLevel()
	End Method


	Method SetLevelStartStep:int(newStep:int)
		if levelStartStep = newStep then return False
		
		levelStartStep = newStep
		levelStartStepTime = GameTime.Millisecs()
		return True
	End Method


	Method GetPlayerProfile:TPlayerProfile()
		if not GameConfig.playerProfile then GameConfig.playerProfile = new TPlayerProfile.Initialize()
		return GameConfig.playerProfile
	End Method
	

	Method GetScore:int()
		return GetPlayerProfile().score
	End Method


	Method AddScore:int(add:int)
		GetPlayerProfile().score :+ add
	End Method


	Method IsGameOver:int()
		return levelStartStep = STARTSTEP_STARTED and currentLevel.GetTimeLeft() <= 0
	End Method


	Function _UpdateEntityList(list:TList)
		local toRemove:TGameEntity[]
		For local entity:TGameEntity = EachIn list
			if entity.IsDead()
'			if not entity.IsAlive()
				toRemove :+ [entity]
				continue
			endif
			
			entity.Update()
		Next

		For local entity:TGameEntity = EachIn toRemove
			list.Remove(entity)
		Next
	End Function


	Method UpdateActiveScoreEntities()
		_UpdateEntityList(activeScoreEntities)
	End Method


	Method UpdateActiveHudEntities()
		_UpdateEntityList(activeHudEntities)
	End Method
	

	Method RenderBackground()
	End Method


	Method RenderHud()
		local screenW:int = GetGraphicsManager().GetWidth()
	
		local font:TBitmapFont = GetBitmapFont("score", 40)

		font.DrawBlock(MathHelper.DottedValue(GetScore()), screenW-50, 10, 190, 60, ALIGN_RIGHT_CENTER)
		if currentLevel
			'font.DrawBlock(int(currentLevel.GetTimeLeft()/1000)+"s", screenW-200, 184, 190, 60, ALIGN_RIGHT_CENTER)
			'font.Draw("level: " + GameConfig.GetPlayerProfile().currentLevelNumber, GetGraphicsManager().GetWidth() - 250, 170)
		endif
	End Method


	Method RenderActiveScoreEntities()
		For local entity:TGameEntity = EachIn activeScoreEntities
			entity.Render()
		Next
	End Method


	Method RenderActiveHudEntities()
		For local entity:TGameEntity = EachIn activeHudEntities
			entity.Render()
		Next
	End Method


	Method RenderIntroduction(introductionKey:string)
		DrawText("Welcome", 0,0)
		'local welcome:string = "Welcome "
		'welcome :+ GameConfig.GetPlayerName()
		'RenderMessage("Welcome ".ToUpper(), "you have to do this and that.")
	End Method


	Method HandleClickedIntroduction:int(introductionKey:string)
		'TODO:
		'if it is a "show one time per profile"-introduction, mark it
		'here in the profile
		'if introductionKey = "XYZ"
		'	GameConfig.GetPlayerProfile().SetIntroductionRead(introductionKey, True)
		'endif
	End Method


	Method Render()
		RenderBackground()

		if currentLevel then currentLevel.Render()

		'draw them on top
		RenderActiveScoreEntities()

		RenderActiveHudEntities()

		RenderHud()

		Select levelStartStep
			case STARTSTEP_INTRODUCTION
				if introductionsToShow.Count() > 0
					local firstIntroduction:string = string(introductionsToShow.First())
					RenderIntroduction(firstIntroduction)
				endif
		End Select
	End Method


	Method Update()
		Super.Update()


		'run sequentially ("if" instead of "select") so things are run
		'each after another instead of waiting an update tick each time
		if levelStartStep = STARTSTEP_NONE
			if levelStartStepTime < 0 then levelStartStepTime = GameTime.Millisecs() 

			'wait 250ms
			if levelStartStepTime + 1500 < GameTime.Millisecs()
				PrepareLevel()
				'show introduce screen
				SetLevelStartStep(STARTSTEP_INTRODUCTION)
			endif
		endif


		if levelStartStep = STARTSTEP_INTRODUCTION
			local canContinue:int = True

			'wait until each introduction got "clicked"
			if introductionsToShow.Count() > 0
				canContinue = False
				'wait for click
				If MouseManager.IsHit(1)
					HandleClickedIntroduction(string(introductionsToShow.First()))
					introductionsToShow.RemoveFirst()

					if introductionsToShow.Count() = 0 then canContinue = True
				endif
			endif

			if canContinue
				SetLevelStartStep(STARTSTEP_START)
			endif
		endif


		if levelStartStep = STARTSTEP_STARTED
			'update timer
			if lastLevelTimerSecond < 0 then lastLevelTimerSecond = GameTime.MilliSecs()
			While GameTime.Millisecs() - lastLevelTimerSecond > 1000
				levelTimer :- 1
				lastLevelTimerSecond :+ 1000
			Wend

			currentLevel.Update()

			UpdateActiveScoreEntities()
		EndIf


		'regardless of step (except none):
		if levelStartStep <> STARTSTEP_NONE
			if currentLevel and currentLevel.IsComplete()
				onFinishLevel()

				SetLevelStartStep(STARTSTEP_NONE)
				GameConfig.GetPlayerProfile().currentLevelNumber :+ 1
				GameConfig.SavePlayerProfile()

				currentLevel = GetLevel( GameConfig.GetPlayerProfile().currentLevelNumber )
			endif
		endif


		UpdateActiveHudEntities()
	End Method


	'override
	Method onStartLevel:int()
		print "starting level " +GameConfig.GetPlayerProfile().currentLevelNumber
	End Method


	'override
	Method onFinishLevel:int()
		print "finished level " +GameConfig.GetPlayerProfile().currentLevelNumber
	End Method
	

	Method onKillEnemy:Int(entity:TGameEntity)
		print "killed an enemy"
		'create score
		local text:TTextEntity = new TTextEntity
		text.value = "100"
		text.area.SetPosition(entity.GetScreenPos().AddXY(0.5*entity.GetScreenWidth(), 0.5*entity.GetScreenHeight()))
		text.area.SetWH(100, -1) 'define some width to "break line" at
		text._font = GetBitmapFont("score", 10)
		text.ResizeToImageCache()

		AddScore(1000)

		text.StartAutoMovementToPosition(new TVec2D.Init(GetGraphicsManager().GetWidth(), 0))

		activeScoreEntities.AddLast(text)
	End Method
End Type

'=== CONVENIENCE ACCESSOR ===
Function GetGame:TGame()
	Return TGame.GetInstance()
End Function