SuperStrict
Import Brl.LinkedList
Import Brl.Map
Import "base.util.time.bmx"
Import "base.network.lockstepsystem.bmx"


'contrary to "TLockStepSystem" all commands are issued directly to the
'server and when the server "ticks" it issues all these commands to all
'connected clients. If a client has all commands for a turn it advances
'to the next round
Type TServerControlledLockStepSystem extends TLockStepSystem
	'mode: 0 = server, 1 = client
	Field mode:int = 0
	Global _instance:TServerControlledLockStepSystem


	Function GetInstance:TServerControlledLockStepSystem()
		if not _instance then _instance = new TServerControlledLockStepSystem
		return _instance
	End Function


	Method IsServer:int()
		return mode = 0
	End Method


	'override
	Method NextStepAvailable:int()
		'server does not wait for queues
		if isServer() then return nextStepTimer <= 0

		return super.NextStepAvailable()
	End Method


	'override
	Method NextStep()
		print "ProcessStep:    "+rset(currentStep, 6)+"  ["+millisecs()+"]"

		'server emits packets to all
		if isServer() then SendActions()

		ProcessStep()

		'reset step timer (add missing time to next step)
		nextStepTimer :+ stepsInterval

		currentStep :+ 1
		For local q:TLockStepActionQueue = EachIn queues
			q.NextTurn()
		Next
	End Method


	Method SendActions()
	End Method


	Method ProcessStep()
		For local q:TLockStepActionQueue = EachIn queues
			For local a:TLockStepAction = EachIn q.GetActions()
				a.Execute()
			Next
		Next
	End Method
End Type


Function GetLockStepSystem:TLockStepSystem()
	return TLockStepSystem.GetInstance()
End Function

