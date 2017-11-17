SuperStrict
Import Brl.LinkedList
Import Brl.Map
Import "base.util.time.bmx"


'contrary to "TLockStepSystem" all commands are issued directly to the
'server and when the server "ticks" it issues all these commands to all
'connected clients. If a client has all commands for a turn it advances
'to the next round
Type TServerStepSystem
	Field lastUpdate:Long = 0
	'milliseconds until next lock step
	Field nextStepTimer:int = 0
	Field stepsInterval:int = 100 'every 100ms - 10x per second
	Field currentStep:int = 0
	Field queues:TList = CreateList()
	'mode: 0 = server, 1 = client
	Field mode:int = 0
	Global _instance:TServerStepSystem


	Function GetInstance:TServerStepSystem()
		if not _instance then _instance = new TServerStepSystem
		return _instance
	End Function


	Method IsServer:int()
		return mode = 0
	End Method


	Method AddQueue(queue:TServerStepActionQueue)
		if not queue then return
		if queues.contains(queue) then return

		'align to current situation
		queue.currentStep = currentStep

		queues.AddLast(queue)
	End Method


	Method GetQueue:TServerStepActionQueue(playerID:int)
		For local q:TServerStepActionQueue = Eachin queues
			if q.playerID = playerID then return q
		Next
		return null
	End Method


	Method GetQueueAtIndex:TServerStepActionQueue(index:int)
		return TServerStepActionQueue(queues.ValueAtIndeX(index))
	End Method


	Method Update:int()
		nextStepTimer :- (Time.GetTimeGone() - lastUpdate)
		lastUpdate = Time.GetTimeGone()

		'move on to next step?
		if NextStepAvailable() then NextStep()
	End Method


	Method NextStepAvailable:int()
		return nextStepTimer <= 0
	End Method


	Method GetCurrentStep:Int()
		return currentStep
	End Method
	

	Method NextStep()
		'execute all confirmed actions
		'clients: execute all confirmed actions
		'         also remove action from confirmed list
		local link:TLink
		local a:TServerStepAction
		For local q:TServerStepActionQueue = EachIn queues
			link = q.GetConfirmed().FirstLink()
			if not link then continue
			While link
				a = TServerStepAction(link.value())
				'execute action
				if a then a.Execute()
				'remove the action
				link.Remove()
				'go on with next
				link = link.NextLink()
			Wend
		Next
		

		'server sends unconfirmed actions to clients
		if isServer()
			SendActionsToClients()
			'confirm them now (for local client)
			For local q:TServerStepActionQueue = EachIn queues
				q.ConfirmPending()
			Next
		endif

		'reset step timer (add missing time to next step)
		nextStepTimer :+ stepsInterval

		currentStep :+ 1
		For local q:TServerStepActionQueue = EachIn queues
			q.NextTurn()
		Next
	End Method


	Method SendActionsToClients()
		'stub function, doing nothing in base class
	End Method
End Type


Function GetServerStepSystem:TServerStepSystem()
	return TServerStepSystem.GetInstance()
End Function




'an action queue for EACH individual player
Type TServerStepActionQueue
	'contains actions not confirmed by the server
	Field pending:TList = CreateList()
	'contains actions already confirmed by the server (and ready to get
	'used during the right step)
	Field confirmed:TList = CreateList()
	Field currentStep:int = 0
	
	Field averageResponseTime:int
	Field lastResponseTime:int
	Field playerID:int = 0


	Method Init:TServerStepActionQueue(playerID:int)
		self.playerID = playerID
		return self
	End Method


	'add an action
	'-> adds it to "pending" until ConfirmPending() is called
	Method AddPending(action:TServerStepAction)
		if pending.contains(action) then return

		print "Add pending action " + action.name+": step="+currentStep

		pending.AddLast(action)
	End Method


	'add an action
	Method AddConfirmed(action:TServerStepAction)
		print "Add confirmed action " + action.name+": step="+currentStep

		confirmed.AddLast(action)
	End Method


	Method NextTurn()
		currentStep :+ 1
	End Method


	'places all pending actions of the given step in the list of
	'confirmed actions
	Method ConfirmPending:int()
		For local action:TServerStepAction = EachIn pending
			confirmed.AddLast(action)
			pending.Remove(action)
		Next

		'adjust average response time
		if lastResponseTime = 0
			averageResponseTime = 0
		else
			averageResponseTime = _weightedAverage(Time.GetTimeGone() - lastResponseTime, averageResponseTime)
		endif
		lastResponseTime = Time.GetTimeGone()
	End Method


	Method GetConfirmed:TList()
		return confirmed
	End Method


	Method GetPending:TList()
		return pending
	End Method


	Function _weightedAverage:int(value:int, average:int, weightA:int=9, weightB:int=1)
		'rise quickly
		if value > average
			average = value
		'fall down slowly
		else
			average = (average * weightA + value * weightB) / (weightA + weightB)
		endif			
		return average
	End Function
End Type



'a server-step-action
Type TServerStepAction
	'id should be something like "player1__changeFigureTarget__1"
	Field name:string = ""
	Field serverStep:int = 0


	Method IsValid:int()
		return True
	End Method


	Method Undo:int() abstract
	Method Execute:int() abstract

	Method Serialize:string() abstract
	Function UnSerialize:TServerStepAction(s:string) abstract
End Type


Type TNullServerStepAction extends TServerStepAction
	'id should be something like "player1__changeFigureTarget__1"
	Field name:string = "null"


	Method Undo:int(); End Method
	Method Execute:int(); End Method

	Method Serialize:string()
		return "NullAction"
	End Method

	Function UnSerialize:TServerStepAction(s:string)
		if s = "NullAction" then return new TNullServerStepAction
		return null
	End Function
End Type
