SuperStrict
Import "Dig/base.util.vector.bmx"
Import "Dig/base.framework.entity.bmx"
Import "Dig/base.util.graphicsmanager.bmx"
Import "game.gametime.bmx"


Type TGameEntity extends TEntity
	Field anim_startPosition:TVec2D
	Field anim_endPosition:TVec2D
	Field anim_startTime:Long = 0
	Field anim_duration:Int = 500
	Field states:Int
	Field alive:int = True


	Method HasState:Int(state:Int) {_exposeToLua}
		Return (states & state) > 0
	End Method


	Method SetState(state:Int, enable:Int=True)
		If enable
			states :| state
		Else
			states :& ~state
		EndIf
	End Method


	Method GetParentEntity:TGameEntity()
		Return TGameEntity(parent)
	End Method


	Method StartAutoMovementToPosition(pos:TVec2D)
		If Not pos Then pos = New TVec2D.Init(0,0)
		anim_startTime = GameTime.MilliSecs()
		anim_startPosition = area.position.copy()
		anim_duration = CalculateMovementDuration(pos)
		anim_endPosition = pos
	End Method


	Method FinishAutoMovement:Int()
		'move to target
		area.SetXY( anim_endPosition.GetX(), anim_endPosition.GetY() )
	End Method


	'checks (eg. parent) if an entity can get dragged
	Method TryDrag:Int()
		If GetParentEntity() And Not GetParentEntity().TryDragEntity(Self) Then Return False

		Return True
	End Method

	Method Drag:Int()
		SetEntityOption(OPTION_IGNORE_PARENT_SCREENCOORDS, True)
		SetEntityOption(OPTION_IGNORE_PARENT_SCREENLIMIT, True)
		Return True
	End Method


	'checks (eg. game rules) if an entity can get dropped to somewhere
	Method TryDrop:Int()
		Return True
	End Method

	Method Drop:Int()
		SetEntityOption(OPTION_IGNORE_PARENT_SCREENCOORDS, False)
		SetEntityOption(OPTION_IGNORE_PARENT_SCREENLIMIT, False)
		Return True
	End Method	


	'ask if a child entity can get dragged
	Method TryDragEntity:Int(entity:TGameEntity)
		Return True
	End Method
	
	'call if a child entity gets dragged
	Method DragEntity:Int(entity:TGameEntity)
		Return True
	End Method


	'decide whether a drop of an entity is allowed
	'eg. "receiver" might not be interested in it
	Method TryDropEntity:Int(entity:TGameEntity)
		If GetParentEntity() And Not GetParentEntity().TryDropEntity(Self) Then Return False

		Return True
	End Method

	'call if an entity gets dropped onto this entity
	Method DropEntity:Int(droppingEntity:TGameEntity, x:Int, y:Int)
		'
	End Method


	'call if this entity gets dropped to another entity
	Method onDropToEntity:Int(entity:TGameEntity)
		Return True
	End Method

	'call if this entity gets dragged from another entity (maybe not parent)
	Method onDragFromEntity:Int(entity:TGameEntity)
		Return True
	End Method


	Method IsAlive:int()
		return alive
	End Method

	'might be more than just "not alive anymore" (eg. "dying = not alive and not dead")
	Method IsDead:int()
		return not alive
	End Method


	Method GetDropZone:TRectangle()
		'by default return the center
		return GetScreenRect()
	End Method


	Method GetMovementDurationBase:int()
		return 500
	End Method


	Method CalculateMovementDuration:Float(targetPosition:TVec2D)
		'calculate duration in dependence to to-move-distance
		Local distance:Float = GetScreenPos().DistanceTo(targetPosition)
		'the movement should be done in 0.5 second when moving from top left to bottom right
		Return GetMovementDurationBase() * (distance / Sqr(GraphicsWidth()^2 + GraphicsHeight()^2))
	End Method
End Type