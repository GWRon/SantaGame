SuperStrict
'to access sprites and their information (eg. width/height)
Import "game.assets.bmx"
'gametime differs from real time (allows "slowdowns")
Import "game.gametime.bmx"



Type TGameLevel
	Field name:string
	Field timeForLevel:int
	Field timeForLevelLeft:int
	Field timeStarted:Long
	'score reached in _this_ level
	Field score:int
	Field started:int = False


	Method Reset:int()
		started = False
		timeForLevelLeft = timeForLevel
	End Method


	Method Start:int()
		Reset()
		started = True
		timeStarted = GameTime.Millisecs()
	End Method


	Method GetTimeAtBegin:int()
		return timeForLevel
	End Method
	

	Method GetTimeLeft:int()
		return Max(0, timeForLevelLeft - (GameTime.Millisecs() - timeStarted))
	End Method


	Method AddTimeLeft(add:int)
		timeForLevelLeft :+ add*1000
	End Method


	Method IsComplete:int()
		'add check when level finished
		return False
	End Method


	Method IsStarted:int()
		return started
	End Method


	Method Update:int()
		'nothing to do 
		if IsComplete() then return False
		if not IsStarted() then return False

		'handle level stuff
		'tower rotation
		'enemy movement
		'player handling
		
		if IsComplete() then print "  GameLevel.Update: Finished level."
	End Method


	Method Render:int()
		DrawText("Implement game.gamelevel.bmx Render()",0, 50)
		'draw tower
		'draw enemies
		'draw player
	End Method
End Type