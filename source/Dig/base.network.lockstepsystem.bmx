SuperStrict
Import Brl.LinkedList
Import Brl.Map
Import "base.util.time.bmx"


Type TLockStepSystem
	Field lastUpdate:Long = 0
	'milliseconds until next lock step
	Field nextStepTimer:int = 0
	Field stepsInterval:int = 100 'every 100ms - 10x per second
	Field currentStep:int = 0
	Field queues:TList = CreateList()
	Global _instance:TLockStepSystem


	Function GetInstance:TLockStepSystem()
		if not _instance then _instance = new TLockStepSystem
		return _instance
	End Function


	Method AddQueue(queue:TLockStepActionQueue)
		if not queue then return
		if queues.contains(queue) then return

		'align to current situation
		queue.currentStep = currentStep

		queues.AddLast(queue)
	End Method


	Method GetQueue:TLockStepActionQueue(playerID:int)
		For local q:TLockStepActionQueue = Eachin queues
			if q.playerID = playerID then return q
		Next
		return null
	End Method


	Method GetQueueAtIndex:TLockStepActionQueue(index:int)
		return TLockStepActionQueue(queues.ValueAtIndeX(index))
	End Method


	Method Update:int()
		nextStepTimer :- (Time.GetTimeGone() - lastUpdate)
		lastUpdate = Time.GetTimeGone()
	End Method


	Method NextStepAvailable:int()
		if AllQueuesConfirmed() then return nextStepTimer <= 0
		return False
	End Method


	Method AllQueuesConfirmed:int()
		For local q:TLockStepActionQueue = EachIn queues
			if q.GetConfirmedStep() < currentStep then return False
		Next
		return True
	End Method


	Method GetUnconfirmedQueues:TLockStepActionQueue[]()
		local result:TLockStepActionQueue[] = new TLockStepActionQueue[0]
		For local q:TLockStepActionQueue = EachIn queues
			if q.GetConfirmedStep() < currentStep
				result :+ [q]
			endif
		Next
		return result
	End Method


	Method GetCurrentStep:Int()
		return currentStep
	End Method
	

	Method NextStep()
		'print ".== LOCK STEP TICK =="
		'print "|- ProcessStep: "+rset(currentStep, 6)+"  ["+millisecs()+"]"
		print "ProcessStep:    "+rset(currentStep, 6)+"  ["+millisecs()+"]"
		ProcessStep()

		'reset step timer (add missing time to next step)
		nextStepTimer :+ stepsInterval

		currentStep :+ 1
		For local q:TLockStepActionQueue = EachIn queues
			q.NextTurn()
		Next


		'execute commands for previous

		'print "|- NextStep:    "+rset(currentStep, 6)+"  ["+millisecs()+"]"
		'print "'===="
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




'an action queue for EACH individual player
Type TLockStepActionQueue
	'contains a list for each turn, only contains unconfirmed entries
	Field pending:TList = CreateList()
	'contains a list for each "turn" stored as "turnString"=>List
	Field confirmed:TMap = CreateMap()
	Field confirmedStep:int = -1
	Field currentStep:int = 0
	
	Field averageResponseTime:int
	Field lastResponseTime:int
	Field playerID:int = 0


	Method Init:TLockStepActionQueue(playerID:int)
		self.playerID = playerID
		return self
	End Method


	'add an action
	'-> adds it to "pending" until ConfirmPending() is called
	'   (which should be done on the end of a "lock step")
	Method Add(action:TLockStepAction)
		if pending.contains(action) then return

		action.lockStep = currentStep + 1
		print "Add action " + action.name+": step="+currentStep

		pending.AddLast(action)
	End Method


	Method NextTurn()
		currentStep :+ 1
	End Method

	'places all pending actions of the given lockStep in the list of
	'confirmed actions
	'once confirmed, you cannot add something to that pending queue
	'anymore (until lockstep changes)
	Method ConfirmPending:int(lockStep:int = -1)
		'confirm the CURRENT
		if lockStep = -1 then lockStep = confirmedStep + 1
		'do not confirm the FUTURE
		lockStep = Min(lockStep, GetLockStepSystem().currentStep)

		'already confirmed that lock step 
		if TList(confirmed.ValueForKey( string(lockStep) )) then return False

		local l:TList = CreateList()
		For local action:TLockStepAction = EachIn pending
'			if action.lockStep = lockStep
				l.AddLast(action)
				pending.Remove(action)
'			endif
		Next
		confirmed.insert(string(lockStep), l)

		'set new lockstep (which is confirmedStep + 1)
		confirmedStep = lockStep

		'adjust average response time
		if lastResponseTime = 0
			averageResponseTime = 0
		else
			averageResponseTime = _weightedAverage(Time.GetTimeGone() - lastResponseTime, averageResponseTime)
		endif
		lastResponseTime = Time.GetTimeGone()

		print "Confirmed pending: player="+playerID+"  step="+lockStep +"  actions="+l.count()
	End Method


	Method GetConfirmedStep:int()
		return confirmedStep
	End Method
	

	Method GetActions:TList(lockStep:int = -1)
		if lockStep = -1 then lockStep = currentStep
		local l:TList = TList(confirmed.ValueForKey( string(lockStep) ))
		if not l then return CreateList()
		return l
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



'a lock-step-action
Type TLockStepAction
	'id should be something like "player1__changeFigureTarget__1"
	Field name:string = ""
	Field lockStep:int = 0


	Method IsValid:int()
		return True
	End Method


	Method Undo:int() abstract
	Method Execute:int() abstract

	Method Serialize:string() abstract
	Function UnSerialize:TLockStepAction(s:string) abstract
End Type

