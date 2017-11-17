SuperStrict
Import "Dig/base.gfx.bitmapfont.bmx"
Import "Dig/base.gfx.sprite.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.interpolation.bmx"
Import "game.gameentity.bmx"
Import "game.gametime.bmx"
Import "game.base.bmx"




Type TTextEntity Extends TGameEntity
	Field value:string
	Field color:TColor
	Field imageCache:TImage
	Field imageCacheMidHandle:int = False
	Field lifeTime:Long
	Field dieTime:Long
	Field movementDurationBase:int = 2000
	Field _fontSize:int = 40
	Field _font:TBitmapFont

	Const STATE_NORMAL:Int = 0
	Const STATE_HAS_LIFETIME:Int = 1
	Const STATE_AUTO_MOVEMENT:Int = 2
	Const STATE_DYING:Int = 4
	Const DIE_DURATION:Float = 750.0

	
	Method New()
	End Method


	Method GenerateGUID:string()
		return "textentity-"+id
	End Method
	

	Method Die:Int()
		SetState(STATE_DYING)
		dieTime = GameTime.MilliSecs()
	End Method


	Method GetDeathProgress:Float()
		'0.0 at begin of dying, and 1.0 at end...when really dead

		If IsDead() Then Return 1.0
		If HasState(STATE_DYING) Then Return Max(0.0, Min(1.0, (GameTime.MilliSecs() - dieTime) / Float(DIE_DURATION)))
		Return 0.0
	End Method


	Method StartAutoMovementToPosition(pos:TVec2D)
		Super.StartAutoMovementToPosition(pos)
		SetState(STATE_AUTO_MOVEMENT)
	End Method


	Method FinishAutoMovement:Int()
		SetState(STATE_AUTO_MOVEMENT, False)

		Super.FinishAutoMovement()
	End Method


	Method GetFont:TBitmapFont()
		if not _font then return GetBitmapFont("default")
		return _font
	End Method


	Method ResizeToImageCache:int()
		if not imageCache 'avoid auto-creation
			imageCache = CreateImageCache(int(area.GetW()), 1000)
		endif

		if GetImageCache()
			area.SetWH( GetImageCache().width, GetImageCache().height )
		endif

		if imageCacheMidHandle then MidHandleImageCache()
	End Method


	Method MidHandleImageCache()
		if not imageCache then return
		SetImageHandle(imageCache, 0.5*imageCache.width, 0.5*imageCache.height )
	End Method


	Method CreateImageCache:TImage(textW:int=-1, textH:int=-1)
		if textW <= 0 then textW = area.GetW()
		if textH <= 0 then textH = area.GetH()
		
		local textDimensions:TVec2D = GetFont().GetBlockDimension(value, textW, textH)
		Local img:TImage = CreateImage(textDimensions.GetIntX(), textDimensions.GetIntY(), DYNAMICIMAGE) 'no FILTEREDIMAGE!
		LockImage(img).ClearPixels(0)

		'set target for fonts
		TBitmapFont.setRenderTarget(img)

		SetColor 255,255,255
		GetFont().DrawBlock(value, 0,0, textDimensions.GetX(), textDimensions.GetY(), ALIGN_CENTER_TOP)

		'remove target again
		TBitmapFont.setRenderTarget(null)

		return img
	End Method


	Method GetImageCache:TImage()
		if not imageCache then imageCache = CreateImageCache()
		if imageCacheMidHandle then MidHandleImageCache()

		return imageCache
	End Method


	'override
	Method GetMovementDurationBase:int()
		return movementDurationBase
	End Method


	Method SetLifetime:int(time:int = 0)
		if time = 0
			lifeTime = 0
			SetState(STATE_HAS_LIFETIME, False)
		else
			lifeTime = GameTime.Millisecs() + time
			SetState(STATE_HAS_LIFETIME, True)
		endif
	End Method
	

	Method Update:Int()
		If HasState(STATE_HAS_LIFETIME)
			if lifeTime < GameTime.Millisecs()
				anim_startTime = GameTime.MilliSecs()
				SetState(STATE_HAS_LIFETIME, False)
			endif
		EndIf
	
		'move to origin or source
		If HasState(STATE_AUTO_MOVEMENT) and not HasState(STATE_HAS_LIFETIME)
			Local timeGonePercentage:Float = Float((GameTime.MilliSecs() - anim_startTime) / Float(anim_duration))
			Local addX:Int = 1.0 * TInterpolation.CircOut(0, anim_endPosition.GetX() - anim_startPosition.GetX(), Min(1.0, timeGonePercentage), 1.0)
			Local addY:Int = 1.0 * TInterpolation.CircOut(0, anim_endPosition.GetY() - anim_startPosition.GetY(), Min(1.0, timeGonePercentage), 1.0)
			area.SetXY( anim_startPosition.GetX() + addX, anim_startPosition.GetY() + addY)

			If timeGonePercentage >= 1.0
				FinishAutoMovement()
				Die()
			EndIf
		EndIf

		If HasState(STATE_DYING) and GetDeathProgress() = 1.0 then alive = false
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		SetImageHandle(GetImageCache(), 0.5*GetImageCache().width, 0.5*GetImageCache().height)

		If HasState(STATE_DYING)
			Local p:Float = GetDeathProgress()
			Local scale:Float = Max(0,  1.0 - TInterpolation.BackInOut(0, 1.0, p, 1.0))
			'Local c:TColor
			'if color
			'	c = color.Copy().AdjustBrightness(float(5 - TInterpolation.BackInOut(0, 5.0, p, 1.0)))
			'else
			'	c = new TColor.Get().AdjustBrightness(float(5 - TInterpolation.BackInOut(0, 5.0, p, 1.0)))
			'endif
			'TODO: change to a "darker" color but stay in the palette

			SetRotation(p * 360)
			SetScale(scale, scale)

			DrawImage(GetImageCache(), GetScreenX(),GetScreenY())
			SetHandle(0, 0)

			SetRotation(0)
			SetScale(1.0, 1.0)
			SetColor(255,255,255)
		Else
			If color
				local oldCol:TColor = new TColor.Get()
				color.SetRGB()
				DrawImage(GetImageCache(), GetScreenX(),GetScreenY())
				oldCol.SetRGB()
			else
				DrawImage(GetImageCache(), GetScreenX(),GetScreenY())
			endif
		EndIf

	End Method
End Type