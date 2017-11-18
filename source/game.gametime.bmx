SuperStrict
import "Dig/base.util.time.bmx"



Type GameTime Extends Time
	Global lastGameMillisecsUpdate:Long = -1
	Global gameMillisecs:Long
	Global speedFactor:Float = 1.0

	Function Update:Int()
		If lastGameMillisecsUpdate = -1 Then lastGameMillisecsUpdate = GameTime.MilliSecs()

		Local timeGone:Long = (Super.MilliSecsLong() - lastGameMillisecsUpdate) * speedFactor
		gameMillisecs :+ timeGone

		lastGameMillisecsUpdate = Super.MilliSecsLong()
	End Function


	Function MilliSecs:Long()
		If lastGameMillisecsUpdate = -1 Then lastGameMillisecsUpdate = Super.MilliSecsLong()

		Local timeGone:Long = (Super.MilliSecsLong() - lastGameMillisecsUpdate) * speedFactor
		Return lastGameMillisecsUpdate + timeGone
	End Function
End Type




Type TGameTimeIntervalTimer Extends TIntervalTimer
	Method Init:TGameTimeIntervalTimer(interval:Int, actionTime:Int = 0, randomnessMin:Int = 0, randomnessMax:Int = 0)
		Super.Init(interval, actionTime, randomnessMin, randomnessMax)
		Return Self
	End Method
	
	'override
	'use game timer instead (for slowdown, pause, ...
	Function _GetTimeGone:Long()
		Return GameTime.MilliSecs()
	End Function
End Type