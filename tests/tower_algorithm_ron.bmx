SuperStrict

Framework brl.glmax2d
Import brl.standardio
Import "../source/Dig/base.framework.entity.bmx"
Import "../source/Dig/base.gfx.bitmapfont.bmx"
Import "../source/Dig/base.util.interpolation.bmx"
Import "../source/Dig/base.util.string.bmx"

Import "../source/Dig/base.framework.entity.spriteentity.bmx"
Import "../source/Dig/base.util.registry.bmx"
Import "../source/Dig/base.util.registry.spriteloader.bmx"
Import "../source/Dig/base.util.registry.imageloader.bmx"
Import "../source/game.gamesprite.bmx"
Import "../source/external/Render2Texture/renderimage.bmx"

'TODO: use render2texture as VirtualResolution is ignored on pixmap scaling

Global multi:Int = 2
Global g:TGraphics = Graphics(320*multi, 200*multi, 0)
SetVirtualResolution(320,200)
'Local gm:TGraphicsManager = GetGraphicsManager()
'gm.SetDesignedResolution(320, 200)
'gm.SetResolution(320*2, 200*2)
'gm.SetVSync(true)
'gm.SetHertz(0)
'gm.InitGraphics()



TBitmapFontManager._defaultFlags = 0 'unset SMOOTHFONT
GetBitmapFontManager().Add("default", "../assets/gfx/fonts/slkscr.ttf", 8, 0)

Local registryLoader:TRegistryLoader = New TRegistryLoader
registryLoader.baseURI = "../"
registryLoader.LoadFromXML("config/assets.xml", True)

TBitmapFont.shadowColor = new TColor.Create(20,12,28)
TBitmapFont.embossColor = new TColor.Create(222,238,214)

Global level:TLevel = New TLevel
Global elf:TTowerPathEntity = New TTowerPathEntity
elf.sprite = GetSpriteFromRegistry("elf.idle")
elf.SetPosition(0*level.tower.COL_WIDTH +10, 5 * TTower.ROW_HEIGHT)
elf.area.SetWH(elf.sprite.GetWidth(), elf.sprite.GetHeight())
'level.tower.entities.AddLast(elf)
'print level.player.GetRow(true)


Global debugText1:String
Global debugText2:String
Global debugText3:String
Global debugText4:String
Global debugText5:String

Const APP_WIDTH:Int = 320
Const APP_HEIGHT:Int = 200
SetClsColor 20,12,28
'global renderImage:TRenderImage = CreateRenderImage(TGraphicsManager._g, 320, 200)
Global renderImage:TRenderImage = CreateRenderImage(g, 320, 200, False)

Function renderImageSetViewPort(x:Int,y:Int,w:Int,h:Int)
	'run original too
	_max2DViewPortFunctionHook(x,y,w,h)
	renderImage.SetViewport(x,y,w,h)
End Function

Global useRenderImage:Int = 0

While Not KeyDown(key_escape)
	debugText1 = ""
	debugText2 = ""
	debugText3 = ""
	debugText4 = ""
	debugText5 = ""

	If KeyHit(KEY_TAB) then level.debug = 1 - level.debug

	If KeyDown(KEY_UP) Then level.camera.area.position.AddY(-1)
	If KeyDown(KEY_Down) Then level.camera.area.position.AddY(+1)
	If KeyDown(KEY_W) Then level.camera.area.position.AddY(-1)
	If KeyDown(KEY_S) Then level.camera.area.position.AddY(+1)
	If KeyDown(KEY_A) Then level.camera.area.position.AddX(-1)
	If KeyDown(KEY_D) Then level.camera.area.position.AddX(+1)
	
	Level.Update()

	If KeyHit(KEY_F)
		level.tower.SetFlatMode(1 - level.tower.flatMode)
		level.PrecalculateForPosition(level.GetCurrentPosition(), True)
	EndIf
	If KeyHit(KEY_R)
		useRenderImage = 1 - useRenderImage
	EndIf


	If KeyHit(KEY_G)
		multi = multi + 1
		If multi = 3 Then multi = 1
		'CloseGraphics(g)
		g = Graphics(320*multi, 200*multi, 0)
		SetVirtualResolution(320,200)

		renderImage = CreateRenderImage(g, 320, 200, False)
	EndIf


	If MouseHit(1)
		Local spawn:TTowerTestPathEntity = New TTowerTestPathEntity
		Local x:Int = level.camera.GetX() + (VirtualMouseX()-APP_WIDTH/2)
		Local y:Int = level.ScreenY2Y(VirtualMouseY())
		spawn.SetPosition(x, y)
		spawn.area.SetWH(Rand(5)+10, Rand(15)+5)
		level.tower.entities.AddLast(spawn)
	EndIf
	

'	If KeyHit(KEY_A)
'		If Not elf.IsJumping() Then elf.StartJumping()
'	EndIf
	

	If useRenderImage
		'GetGraphicsManager().ResetVirtualGraphicsArea()
		SetRenderImage(renderImage)
		_setViewPortFunctionHook = renderImageSetViewPort
	EndIf
		SetColor 20,12,28
		DrawRect(0,0,320,200)
		'cls

		Level.Render()

		if level.debug
			GetBitmapFont().Draw(debugText1, 0, APP_HEIGHT - 6*7)
			GetBitmapFont().Draw(debugText2, 0, APP_HEIGHT - 5*7)
			GetBitmapFont().Draw(debugText3, 0, APP_HEIGHT - 4*7)
			GetBitmapFont().Draw(debugText4, 0, APP_HEIGHT - 3*7)
			GetBitmapFont().Draw(debugText5, 0, APP_HEIGHT - 2*7)
		endif

	If useRenderImage
		_setViewPortFunctionHook = _max2DViewPortFunctionHook
		SetRenderImage(Null)
		'GetGraphicsManager().SetupVirtualGraphicsArea()

		If renderImage
			DrawImage(renderImage,0,0)
		EndIf
	EndIf

	Flip 1
Wend




Type TLevel
	Field tower:TTower
	Field player:TPlayer
	Field camera:TCamera
	Field x:Int
	Field y:Int
	Field starsX:Int[64]
	Field starsY:Int[64]

	Field debug:int = False

	'precalculated values for current tower position
	Field _precalculatedEffColWidths:Int[18]
	Field _precalculatedTileScreenX:Int[18]
	Field _precalculatedTowerScreenX:Int[18]
	Field _precalculatedColAngles:Int[18]
	Field _precalculatedForPosition:Int = -1 

	'raise the tower by this
	Global GROUND_HEIGHT:Int = 10


	Method New()
		tower = New TTower.Init(18, 70)
		If Not tower.flatMode
			tower.area.SetXY(70,0)
		EndIf

		player = New TPlayer
		player.sprite = GetSpriteFromRegistry("santa.idle")
'		player.SetPosition(14*level.tower.COL_WIDTH +10, 16 * TTower.ROW_HEIGHT)
		player.SetPosition(GetColX(16) +10, GetRowY(tower.rows-1 -3))
		player.area.SetWH(player.sprite.GetWidth(), player.sprite.GetHeight())
		tower.entities.AddLast(player)

		camera = New TCamera
		camera.SetParent(tower)
		camera.target = player
		camera.area.dimension.SetXY(300,240)

		For Local i:Int = 0 Until 64
			starsX[i] = Rand(0, 320)
			starsY[i] = Rand(0, tower.GetHeight())
		Next
	End Method


	Method Reset:Int()
	End Method


	Method Init()
	End Method


	Function Lerp:Float(v:Float, addPerSecond:Float, dt:Float)
		 Return v + (addPerSecond * dt)
	End Function


	Function WrapValue:Float(v:Float, vMin:Float, vMax:Float)
		If v < vMin
			Return vMax - (vMin - v) Mod (vMax - vMin)
		Else
			Return vMin + (v - vMin) Mod (vMax - vMin)
		EndIf
	End Function


	'transform tower-x-coord to screen coord
	Method X2ScreenX:Float(x:Float, radius:Int=-1)
		x :- camera.GetX()

		If Not tower.flatMode
			If radius = -1 Then radius = tower.radiusInner
			Return radius * Sin((tower.WrapX(x) / Float(tower.GetWidth()) * 180.0/Pi) * 2.0 * Pi)
		Else
			x = tower.WrapX(x)
			If (x > (tower.GetWidth()/2.0))
				x = -(tower.GetWidth() - x)
			EndIf
			'avoid border-flickering on the most left bricks
			If x < 0 - tower.radiusInner
				x :- 1
			EndIf
			Return x
		EndIf
	End Method


	'transform tower-y-coord to screen coord
'	Method Y2ScreenY:Float(y:Float)
'		Return tower.GetHeight() - GROUND_HEIGHT - (tower.GetY() - camera.area.GetY())
'	End Method
	

	'transform local y to renderY
	Method Local2ScreenY:Float(y:Float)
		Return y - camera.area.GetY()
	End Method


	Method X2Angle:Int(x:Int, radius:Int = -1)
		Return WrapValue(tower.X2Angle(x - camera.area.GetX()), -180, 180)
	End Method


	Method IsBackSide:Int(angle:Int)
		Return angle <= -90 Or angle >= 90
	End Method


	Method IsFrontSide:Int(angle:Int)
		Return Not IsBackSide(angle)
	End Method


	Method IsLeftSide:Int(angle:Int)
		Return (angle < 0 And angle >= -180)
	End Method


	Method IsRightSide:Int(angle:Int)
		Return Not IsLeftSide(angle)
	End Method


	Method GetCol:Int(x:Int)
		Return WrapValue(x / tower.COL_WIDTH, 0, tower.cols)
	End Method


	Method GetColX:Int(col:Int)
		Return WrapValue(col, 0, tower.cols) * tower.COL_WIDTH
	End Method


	Method GetRow:Int(y:Int)
		Return Min(tower.rows*TTower.ROW_HEIGHT, Max(0, y / TTower.ROW_HEIGHT))
	End Method


	Method GetRowY:Int(row:Int)
		Return row * TTower.ROW_HEIGHT
	End Method


	Method GetRowBottomY:Int(row:Int)
		Return row * TTower.ROW_HEIGHT + TTower.ROW_HEIGHT-1 
	End Method


	'untested
	Method ScreenY2Row:Int(screenY:Int)
		Return ScreenY2Y(screenY) / TTower.ROW_HEIGHT
	End Method


	Method ScreenY2Y:Int(screenY:Int)
		Return screenY + camera.area.GetY()
	End Method


	Method GetColAngle:Int(col:Int, centerOfCol:Int = True)
		'return angle of the center of the column if desired
		If centerOfCol
			Return X2Angle(col * tower.COL_WIDTH + 0.5 * tower.COL_WIDTH)
		Else
			Return X2Angle(col * tower.COL_WIDTH)
		EndIf
	End Method


	Method PrecalculateForPosition:Int(position:Int, forcePrecalculation:Int = False)
		If _precalculatedForPosition = position And Not forcePrecalculation Then Return False


		For Local col:Int = 0 To _precalculatedTileScreenX.length-1
			_precalculatedTileScreenX[col] = int(level.X2ScreenX(col * tower.COL_WIDTH, tower.radiusOuter) + tower.radiusInner + 0.5)
			_precalculatedTowerScreenX[col] = int(level.X2ScreenX(col * tower.COL_WIDTH, tower.radiusInner) + tower.radiusInner + 0.5)
		Next

		_precalculatedForPosition = position

		Return True
	End Method


	Method GetCurrentPosition:Int()
		Return camera.GetX() * 10 '*10 for floating point 
	End Method


	Method GetTileScreenX:Int(col:Int)
		PrecalculateForPosition( GetCurrentPosition() )
		Return _precalculatedTileScreenX[ WrapValue(col, 0, _precalculatedTileScreenX.length)]
		'return level.X2ScreenX(col * tower.COL_WIDTH, tower.radiusOuter) + tower.radiusInner + 0.5
	End Method


	Method GetTowerScreenX:Int(col:Int)
		PrecalculateForPosition( GetCurrentPosition() )
		Return _precalculatedTowerScreenX[ WrapValue(col, 0, _precalculatedTowerScreenX.length)]
		'return level.X2ScreenX(col * tower.COL_WIDTH, tower.radiusInner) + tower.radiusInner + 0.5
	End Method


	Method RenderBackground()
		RenderBackground_Stars()
	End Method


	Method RenderBackground_Stars()
		Local startX:Int = WrapValue(APP_WIDTH  * camera.GetX()/Float(tower.GetWidth()), 0, APP_WIDTH)
		Local startY:Int = Local2ScreenY(0)
'		Local startY:Int = WrapValue(-APP_HEIGHT * camera.GetY()/Float(tower.GetHeight()), 0, APP_HEIGHT)
		For Local i:Int = 0 Until 64
			If i Mod 2 = 0
				SetColor 218,212,94
			Else
				SetColor 222,238,214
			EndIf
			'wrap around rotating axis
			Local starX:Int = WrapValue(startX + starsX[i], 0, APP_WIDTH)
			'ignores virtual resolution
			'Plot(starX, startY + starsY[i])
			DrawRect(starX, startY + starsY[i], 1,1)
		Next
		SetColor 255,255,255
	End Method


	Method RenderForeground()
		'draw ground _after_ tower, so a "tower in destruction" can move
		'downwards without trouble
		SetColor 255,255,255
		Local startOffset:Int = camera.area.GetX()
		Local groundSprite:TSprite = GetSpriteFromRegistry("ground")
		Local groundStartY:Int = -camera.GetY() + tower.GetHeight() + 2
		groundSprite.TileDrawHorizontal(-startOffset Mod groundSprite.GetWidth(), groundStartY, APP_WIDTH + groundSprite.GetWidth(), ALIGN_LEFT_BOTTOM)


		SetColor 255,255,255
		Local hudBG:TSprite = GetSpriteFromRegistry("hud.top.bg")
		hudBG.TileDrawHorizontal(0, 0, APP_WIDTH, ALIGN_LEFT_TOP)

		Local hudLevel:TSprite = GetSpriteFromRegistry("hud.top.level")
		hudLevel.Draw(10, 0)
		GetBitmapFont().DrawBlock("Lvl.1", 15, 5, 31, 15, ALIGN_CENTER_CENTER, TBitmapFont.embossColor, TBitmapFont.STYLE_SHADOW, 1, 2.0)
	End Method


	Method RenderDebug()
		Local startX:Int = WrapValue(APP_WIDTH  * camera.GetX()/Float(tower.GetWidth()), 0, APP_WIDTH)
		Local startY:Int = WrapValue(APP_HEIGHT * camera.GetY()/Float(tower.GetHeight()), 0, APP_HEIGHT)
		SetColor 208,70,72
		GetBitmapFont().DrawStyled("start: x="+startX+" y="+startY, 0,0, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("camera: x="+Int(camera.GetX())+" y="+Int(camera.GetY())+"  targetX="+Int(camera.target.GetX()), 0,7, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("tower: w="+Int(tower.GetWidth())+" h="+Int(tower.GetHeight())+" cols="+tower.cols+" rows="+tower.rows, 0,14, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("player: x="+Int(player.GetX())+" y="+Int(player.GetY())+" rx="+Int(player.area.GetX()), 0,21, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)


		Local feetXOnRightTile:Int = player.GetFeetXOnRightTile()
		Local feetXOnTile:Int = player.GetFeetXOnTile()
		Local feetOnRightTile:Int = player.GetFeetOnRightTile()
		Local feetOnTile:Int = player.GetFeetOnTile()
'		SetColor 0,0,0
'		DrawRect(0,APP_HEIGHT - 10*7 - 1, 90, 14)
		SetColor 222,238,214
		GetBitmapFont().DrawStyled("feet X: L="+feetXOnTile+"  R="+feetXOnRightTile, 0, 28, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("feet T: L="+feetOnTile+"  R="+feetOnRightTile, 0, 35, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)

		GetBitmapFont().Draw(level.ScreenY2Y(VirtualMouseY())+"  " + GetRow(ScreenY2Y(VirtualMouseY())), VirtualMouseX() + 5, VirtualMouseY())

		SetColor 255,255,255
	End Method
	

	Method Update:Int()
		'player.Update()
		
		tower.Update()

		camera.Update()
	End Method


	Method Render:Int()
		'=== RENDER ===
		'adjust interpolation
'		Local dt:Float = GetDeltaTimer().GetTween()
'		player.area.position.x = Tower.WrapX(player.GetX() + TInterpolation.Linear(0, player.velocity.GetX(),  dt, 1.0))
'		player.area.position.y = player.GetY() + TInterpolation.Linear(0, player.velocity.GetY(),  dt, 1.0)
'		camera.area.position.x = tower.WrapX(player.GetX() + TInterpolation.Linear(0, player.velocity.GetX(),  dt, 1.0))
'		camera.area.position.y = camera.GetY() + TInterpolation.Linear(0, camera.velocity.GetY(),  dt, 1.0)

		'limit tweened position
		player.area.position.y = Max(0, player.area.position.y)
		camera.area.position.y = Max(0, camera.area.position.Y)

		RenderBackground()

		tower.Render(0, -camera.GetY())
'		DrawRect(50,tower.GetScreenY() - camera.GetY(), 10,10)

		RenderForeground()

		if debug then RenderDebug()
	End Method
End Type




Type TTower Extends TEntity

	Field tiles:TTowerTile[]
	Field entities:TList = CreateList()
	Field unhandledEntities:TList = CreateList()
	Field cols:Int
	Field rows:Int
	Field radiusInner:Int
	Field radiusOuter:Int

	'show 3d or 2d tower?
	Global flatMode:Int = False
	Global debugView:Int = False

	Global COL_WIDTH:Int = 32 '31 '27
	Global ROW_HEIGHT:Int = 10 '33 '27
	Global ROW_SURFACE:Int = 12 '3
	Global PLATFORM_WIDTH:Int = 0

	Const TILETYPE_GROUND:Int = -1
	Const TILETYPE_AIR:Int = 0
	Const TILETYPE_PATH:Int = 1

	
	Method Init:TTower(cols:Int, rows:Int)
		Local map:String
		map :+ "==================~n"
		map :+ "         o        ~n"
		map :+ "xxx     xxx       ~n"
		map :+ "      xx          ~n"
		map :+ "     x            ~n"
		map :+ " xx x            x~n"
		map :+ "               xx ~n"
		map :+ "              x   ~n"
		map :+ "      xx xx xx    ~n"
		map :+ "     x            ~n"
		map :+ "     x            ~n"
		map :+ "   xx             ~n"
		map :+ "xx x          xxxx~n"
		map :+ "  xx        xx    ~n"
		map :+ "         xxx      ~n"
		map :+ "        x         ~n"
		map :+ "        x         ~n"
		map :+ "x     xx       xxx~n"
		map :+ " x   x       x    ~n"
		map :+ "             x    ~n"
		map :+ "                  ~n"
		map :+ "     x x x        ~n"
		map :+ "     xxx x        ~n"
		map :+ "     x x x  x x x ~n"
		map :+ "                  ~n"
		map :+ "   xxx            ~n"
		map :+ " xx               ~n"
		map :+ "x                x~n"
		map :+ "              xx  ~n"
		map :+ "           xxx    ~n"
		map :+ "        x x       ~n"
		map :+ "   xxxxx          ~n"
		map :+ " xx               ~n"
		map :+ "x                 ~n"
		map :+ "               xx ~n"
		map :+ "            xxx   ~n"
		map :+ "         xxx      ~n"
		map :+ "        x         ~n"
		map :+ "     xxx          ~n"
		map :+ "xxxxxxxxxxxxxxxxxx"
		

		'override with map data
		cols = 18
		rows = map.split("~n").length


		Self.cols = cols
		Self.rows = rows
		tiles = New TTowerTile[cols * rows]
		area.SetWH(cols * COL_WIDTH, rows  * ROW_HEIGHT)

		SetFlatMode(False)

		InitTilesFromString(map)

For Local y:Int = 0 Until rows
	Local line:String = ""
	Local r:Int = y
	For Local x:Int = 0 Until cols
		If GetTile(x,y) And GetTile(x,y).tileType = 1
			r = GetTile(x,y).row
			line :+ RSet(GetTile(x,y).col,2).Replace(" ", "0")+" "
		Else
			line :+ "   "
		EndIf
	Next
	Print RSet(y,2)+":  |" + line+"|   row="+r
Next

'if GetTile(2,2-1)
'	print GetTile(2,2-1).row
'endif
'end

		entities.clear()
		
		
		Return Self
	End Method


	Method SetFlatMode(bool:Int)
		flatMode = bool

		If Not flatMode
			area.SetXY(70,0)
		Else
			area.SetXY(0,0)
		EndIf

		
		'method 1) (define by radius)
		'COL_WIDTH = ceil(2*pi*radiusInner / cols)
		'method 2) (define by COL_WIDTH)
		radiusInner = (cols * COL_WIDTH) / (2*Pi) + 0.5

		'radius = GetWidth() / 4
		'radiusInner = APP_WIDTH / 4
		If flatMode Then radiusInner = radiusInner * 2
		

		radiusOuter = radiusInner * 1.2

		'this.platformWidth = FLAT ? COL_WIDTH : 2 * tower.or * Math.tan((360/tower.cols) * Math.PI / 360);
		If flatMode
			PLATFORM_WIDTH = COL_WIDTH
		Else
			PLATFORM_WIDTH = 2 * radiusOuter * Tan((360.0/cols * 180.0/Pi) * Pi/360.0)
		EndIf
	End Method


	Method InitTilesFromString:Int(s:String, mapWidth:Int = -1)
		Local lines:String[] = s.split("~n")
		Local index:Int = 0
		Local lineIndex:Int = 0

		If mapWidth = -1 Then mapWidth = lines[0].length

'		index = (lines.length-1) * mapWidth
		For Local lineNumber:Int = 0 Until lines.length
			Local line:String = lines[lineNumber]
			lineIndex = 0

			For Local i:Int = 0 Until line.length
				Local tileType:Int = 0
				If line[i] = Asc("x") Then tileType = 1

				If tileType > 0
					tiles[index + lineIndex] = New TTowerTile
					tiles[index + lineIndex].tileType = tileType
					tiles[index + lineIndex].col = lineIndex
					tiles[index + lineIndex].row = lineNumber
					tiles[index + lineIndex].area.SetWH(COL_WIDTH, ROW_HEIGHT)
				EndIf
				
				lineIndex :+ 1
			Next
'			index :- mapWidth
			index :+ mapWidth
		Next
	End Method


	'=== HELPER ===

	'wrap x coord within tower limits
	Method WrapX:Float(x:Float)
		Return TLevel.WrapValue(x, 0, area.GetW())
	End Method


	'wrap column  around to stay within tower boundary
	Method WrapCol:Float(col:Int)
		Return TLevel.WrapValue(col, 0, cols)
	End Method


	Method WrappedRectsIntersect:Int(rectA:TRectangle, rectB:TRectangle)
		If rectA.Intersects(rectB) Then Return True
		'check unwrapped parts
		If Not (rectA.GetY() < rectB.GetY2() And rectA.GetY2() > rectB.GetY()) Then Return False	


		'split rectangles into two - before the wrap and after the wrap
		Local rectA1:TRectangle = rectA
		Local rectA2:TRectangle
		Local rectB1:TRectangle = rectB
		Local rectB2:TRectangle
		If rectA.GetX() <= GetWidth() And rectA.GetX2() > GetWidth()
			rectA1 = New TRectangle.Init(rectA.GetX(), rectA.GetY(), GetWidth() - rectA.GetX(), rectA.GetH())
			rectA2 = New TRectangle.Init(0, rectA.GetY(), rectA.GetX2() - GetWidth(), rectA.GetH())
'print "split a: " + rectA.ToString()+"  =>  " + rectA1.ToString()+"  " + rectA2.ToString() +"  b: "+rectB.ToString()
		EndIf
		If rectB.GetX() <= GetWidth() And rectB.GetX2() > GetWidth()
			rectB1 = New TRectangle.Init(rectB.GetX(), rectB.GetY(), GetWidth() - rectB.GetX(), rectB.GetH())
			rectB2 = New TRectangle.Init(0, rectB.GetY(), rectB.GetX2() - GetWidth(), rectB.GetH())
'print "split b: " + rectB.ToString()+"  =>  b1: " + rectB1.ToString()+"   b2: " + rectB2.ToString() +"  a: "+rectA.ToString()
		EndIf
'local testA:TRectangle  = new TRectangle.Init(0,290,32,10)
'local testB:TRectangle  = new TRectangle.Init(0,259,8,32)
'if not testA.Intersects(testB) then throw "ups"

		
'weitermachen, warum es bei col1,29 durchfaellt
		If rectA1.intersects(rectB1) Then Return True
		If rectB2 And rectA1.intersects(rectB2) Then Return True
		If rectA2 And rectA2.intersects(rectB1) Then Return True
		If rectA2 And rectB2 And rectA2.intersects(rectB2) Then Return True
		Return False
		
Rem
		local aX:int = WrapX(rectA.GetX())
		local aX2:int = aX + rectA.GetW()
		local bX:int = WrapX(rectB.GetX())
		local bX2:int = bX + rectB.GetW()
		local wrappedA:int = False
		local wrappedB:int = False
		if aX <> rectA.GetX()
			wrappedA = True
		elseif aX2 > GetWidth()
			wrappedA = True
		endif
		if bX <> rectB.GetX()
			wrappedB = True
		elseif bX2 > GetWidth()
			wrappedB = True
		endif

		if wrappedB
'			print bX+" " + bX2
			bX :- GetWidth()
			bX2 :- GetWidth()
		endif
endrem
Rem

		local aX:int = WrapX(rectA.GetX())
		local aX2:int = aX + rectA.GetW()
		local bX:int = WrapX(rectB.GetX())
		local bX2:int = bX + rectB.GetW()

		if not (aX < bX2 AND aX2 > bX)
			aX = WrapX(rectA.GetX() +100)
			aX2 = aX + rectA.GetW()
			bX = WrapX(rectB.GetX() +100)
			bX2 = bX + rectB.GetW()
			if not (aX < bX2 AND aX2 > bX)
				aX = WrapX(rectA.GetX() -100)
				aX2 = aX + rectA.GetW()
				bX = WrapX(rectB.GetX() -100)
				bX2 = bX + rectB.GetW()
			endif
		endif
endrem			
Rem
		local wrappedA:int = False
		local wrappedB:int = False
		if aX <> rectA.GetX()
			wrappedA = True
		elseif aX2 > GetWidth()
			wrappedA = True
		endif
		if bX <> rectB.GetX()
			wrappedB = True
		elseif bX2 > GetWidth()
			wrappedB = True
		endif

		if wrappedA<>wrappedB
			if wrappedA
				bX :+ GetWidth()
				bX2 :+ GetWidth()
			elseif wrappedB
				aX :+ GetWidth()
				aX2 :+ GetWidth()
			endif
		endif
endrem
'rem
'if rectA.GetX() > 500 or rectA.GetX() < 10 and rectA.GetY() = 280
'	print rectA.ToString() + "    " + rectB.ToString() +"   aX="+aX+" aX2="+ax2+" bX="+bX+" bX2="+bX2
'endif
'		return aX < bX2 AND aX2 > bX
Rem
		local result:int = aX < bX2 AND aX2 > bX
	
		'check for case 4
		if not result then result = aX < bX2+GetWidth() AND aX2 > bX+GetWidth()
		'check for case 5
		'if not result then result = aX+GetWidth() < bX2 AND aX2+GetWidth() > bX
		return result
endrem
	End Method


	'convert x coord to column number
	Method X2Col:Int(x:Float)
		Return Int(WrapX(Int(x+0.5)) / COL_WIDTH)
	End Method


	'convert y coord to row number
	Method Y2Row:Int(y:Float)
		Return Int(Int(y+0.5) / ROW_HEIGHT)
	End Method


	'convert column to coord
	Method Col2X:Float(col:Float)
		Return col * COL_WIDTH
	End Method


	'convert row to coord
	Method Row2Y:Float(row:Float)
		Return row * ROW_HEIGHT
	End Method


	'convert x coord to angle (360 = one time around the tower)
	Method X2Angle:Int(x:Float, radius:Int = -1)
		If radius = -1 Then radius = area.GetW()/2 ' radius = radiusInner
		Return 360 * (WrapX(x) / (2*radius))
	End Method


	'returns whether an x coord is near a column's center
	Method IsNearColumnCenter:Int(x:Float, column:Int, limit:Int)
		Return limit > Abs(x - Col2X(column + 0.5)) / ( COL_WIDTH / 2.0)
	End Method


	'returns whether a y coord is near the surface of a row
	Method IsNearRowSurface:Int(y:Float, row:Int)
		Return y > (Row2Y(row + 1) - ROW_SURFACE)
	End Method


	Method GetTileByXY:TTowerTile(x:Int, y:Int)
		Return GetTile(X2Col(x), Y2Row(y))
	End Method
	

	Method GetTile:TTowerTile(col:Int, row:Int)
		If row < 0
			'ground
			Return Null
		ElseIf row >= rows
			'air
			Return Null
		Else
			'wrap cols
			col = TLevel.WrapValue(col, 0, cols)
			Return tiles[row * cols + col ]
		EndIf
	End Method


	Method GetNextTile:TTowerTile(col:Int, row:Int, leftRight:Int=0, upDown:Int=0, tileType:Int)
		Local result:TTowerTile
		
		If leftRight = -1
			'search left
		ElseIf leftRight = +1
			'search right
		ElseIf upDown = -1
			'search upwards
			For Local i:Int = row Until 0 Step -1
				result = GetTile(col, i)
				If GetTile(col, i).tileType = tileType Then Return result
			Next
		ElseIf upDown = +1
			'search downwards
			For Local i:Int = row Until rows
				result = GetTile(col, i)
				If GetTile(col, i).tileType = tileType Then Return result
			Next
		EndIf
		
		Return Null
	End Method


	Method RenderMapTiles(colMin:Int, colMax:Int, direction:Int, limitSide:Int = 0, xOffset:Int=0, yOffset:Int=0)
		Local rowMin:Int = Max(0, Y2Row(level.camera.area.GetY() - level.GROUND_HEIGHT))
		Local rowMax:Int = Min(rows - 1, rowMin + (APP_HEIGHT / ROW_HEIGHT + 1))
		Local cell:Int
		Local col:Int = colMin

		While col <> colMax
			'from top to bottom (to hide "shadows")
			For Local row:Int = rowMin To rowMax
				Local tile:TTowerTile = GetTile(col, row)
				If Not tile Then Continue
				tile.RenderPathEntityShadows(xOffset, yOffset)
			Next
			col = WrapCol(col + direction)
		Wend
		col = colMin


		While col <> colMax
			'from top to bottom (to hide "shadows")
			For Local row:Int = rowMin To rowMax
				Local tile:TTowerTile = GetTile(col, row)
				If Not tile Then Continue
				tile.Render(xOffset, yOffset)

				'render attached entities
				tile.RenderPathEntities(xOffset, yOffset)
			Next
			col = WrapCol(col + direction)
		Wend
	End Method


	Method RenderBackgroundTiles:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		Local l:Int = X2Col(level.camera.area.GetX() - GetWidth()/4.0 )
		Local r:Int = X2Col(level.camera.area.GetX() + GetWidth()/4.0)

		'render parts of the map left and right of the tower
		RenderMapTiles(WrapCol(l - 1), WrapCol(l + 1), +1, -1, xOffset, yOffset)
		RenderMapTiles(WrapCol(r + 2), WrapCol(r - 1), -1, -1, xOffset, yOffset)
	End Method
	
	
	Method RenderFrontTiles:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		Local l:Int = X2Col(level.camera.area.GetX() - GetWidth()/4.0 - 1*COL_WIDTH)
		Local c:Int = X2Col(level.camera.area.GetX())
		Local r:Int = X2Col(level.camera.area.GetX() + GetWidth()/4.0)

		'render parts of the map left and right of the tower
		RenderMapTiles(l, WrapCol(c    ), +1, +1, xOffset, yOffset)
		RenderMapTiles(r, WrapCol(c - 1), -1, +1, xOffset, yOffset)
	End Method


	Method RenderBackground:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		If Not flatMode
			Local top:Int = Max(0, yOffset + GetHeight())
			Local bottom:Int = Min(APP_HEIGHT, yOffset + TTower.ROW_HEIGHT)

			Local vpX:Int, vpY:Int, vpH:Int, vpW:Int
	'		GetViewport(vpX, vpY, vpW, vpH)
	'		if renderImage then renderImage.SetViewport(GetScreenX(), top, radiusInner*2-1, bottom-top)

			'render background
			SetColor 20,12,28
			DrawRect(GetScreenX(), top, radiusInner*2, bottom - top)
			SetColor 255,255,255

			RenderBricks(xOffset, yOffset, alignment)

	'		SetViewport(vpX, vpY, vpW, vpH)
		Else
			RenderBricks(xOffset, yOffset, alignment)
		EndIf

		SetColor 255, 255, 255
    End Method
    
	
	Method RenderBricks:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		'offset tiles/bricks every odd/even row
'		local offsets:Float[] = [0.0, 0.30, 0.6, 1.2]
		Local offsets:Float[] = [0.0]
		Local offset:Int = 0

		'every 3rd
		For Local row:Int = 0 Until rows Step 3
			Local rowY:Int = yOffset + row * ROW_HEIGHT
			'visible?
			'-3*ROW_HEIGHT = 1 Brick
			If MathHelper.inInclusiveRange(rowY, -3*ROW_HEIGHT, APP_HEIGHT)
				RenderBrickRow(rowY, offsets[offset], xOffset, yOffset)
			EndIf
			offset = (offset + 1) Mod offsets.length
		Next
	End Method


	Method RenderBrickRow(y:Float, offset:Float, xOffset:Float = 0, yOffset:Float = 0)
		For Local col:Int = 0 Until cols
			Local colX:Int = (col + offset) * COL_WIDTH
			Local x:Int = level.X2ScreenX(colX) + radiusInner + 0.5
			Local effWidth:Int
			If flatMode
				effWidth = COL_WIDTH
			Else
				Local xNext:Int = level.X2ScreenX(colX + COL_WIDTH) + radiusInner + 0.5
				'first next approach: using the x and xNext is required (+0.5)
				'and a "level.X2ScreenX(colX + COL_WIDTH) - level.X2ScreenX(colX)"
				'is not working properly! (jitters) 
				effWidth = xNext - x
				'angle based approach
				'effWidth = floor(cos(abs(angle)) * COL_WIDTH)
			EndIf

			'skip negative or invisible walls (like front to background)
			If effWidth <= 0 Then Continue

			Local angle:Int = level.WrapValue( X2Angle(colX + 0.5 * COL_WIDTH) - X2Angle(level.camera.area.GetX()), -180, 180)
'			If Not flatMode And Not MathHelper.inInclusiveRange(angle, -90, 90) Then Continue

			GetSpriteFromRegistry("wall."+((col Mod 3) +1)).DrawResized(New TRectangle.Init(GetScreenX() + x, y, effWidth, 3*ROW_HEIGHT))
			'DrawOval(GetScreenX() + x-5, 130, 10, 10)
			'GetBitmapFont().Draw(angle, GetScreenX() + x + 5, y + 5)
		Next
	End Method
	
	
	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		RenderBackgroundTiles(xOffset, yOffset)

		'render bricks/background - the "tower"
		RenderBackground(xOffset, yOffset, alignment)

		'render entities not belonging to a tile
		If unhandledEntities.Count() > 0
			For Local pathEntity:TTowerPathEntity = EachIn entities
				pathEntity.RenderShadow(xOffset, yOffset)
			Next
		EndIf


		RenderFrontTiles(xOffset, yOffset)

		'render entities not belonging to a tile
		If unhandledEntities.Count() > 0
			'print "rendering " + unhandledEntities.Count() +" entities."
			For Local pathEntity:TTowerPathEntity = EachIn entities
				pathEntity.Render(xOffset, yOffset)
			Next
		EndIf

		Rem
		For local r:int = 0 until rows
			if r mod 2
				SetColor 200,200,200
			else
				SetColor 100,100,100
			endif
			local rowStartY:int = Row2Y(r)
			DrawRect(xOffset + 20, yOffset + rowStartY, 30, ROW_HEIGHT)
			SetColor 255,255,255
			GetBitmapFont().Draw(r, xOffset + 22, yOffset + rowStartY + 2)
			
		Next
		endrem
	End Method


	Method Update:Int()
		Super.Update()

		'update all tiles (and their children)
		'(so update their positions and the likes)
		'call it before to make "GetTopY()" and the likes work correctly
		For Local t:TTowerTile = EachIn tiles
			t.Update()
		Next


		If unhandledEntities.Count() > 0 Then unhandledEntities.Clear()

		For Local pathEntity:TTowerPathEntity = EachIn entities
			Local currentCol:Int = pathEntity.GetCol()
			Local currentRow:Int = pathEntity.GetRow()
			Local currentTile:TTowerTile = GetTile( currentCol, currentRow )
			
			pathEntity.Update()

			'attach to current tile (if not done before)
			'or new tile (if moved to another tile)
			Local newTile:TTowerTile = GetTile( pathEntity.GetCol(), pathEntity.GetRow())
			If newTile And currentTile = newTile
				If Not currentTile.HasPathEntity(pathEntity)
					currentTile.AddPathEntity(pathEntity)
				EndIf
			EndIf	
			If currentTile <> newTile
				'print "tile changed"
				If currentTile Then currentTile.RemovePathEntity(pathEntity)
				If newTile Then newTile.AddPathEntity(pathEntity)
				currentTile = newTile
			EndIf
			If Not currentTile Then unhandledEntities.AddLast(pathEntity)
		Next
	End Method
End Type





Type TTowerTile Extends TTowerEntity
	Field tileType:Int
	Field row:Int
	Field col:Int
	Field frontWidth:Int
	'children are upated/rendered automatically, pathEntities are
	'not handled automatically (rendered/updated by tower object)
	Field pathEntities:TTowerPathEntity[]


	Method New()
		area.SetWH(level.tower.COL_WIDTH,TTower.ROW_HEIGHT)
	End Method


	Method HasPathEntity:Int(child:TTowerPathEntity)
		For Local c:TTowerPathEntity = EachIn pathEntities
			If child = c Then Return True
		Next
		Return False
	End Method


	Method AddPathEntity(child:TTowerPathEntity, index:Int = -1)
		If Not child Then Return
		If Not pathEntities Then pathEntities = New TTowerPathEntity[0]

		If index < 0 Then index = pathEntities.length
		If index >= pathEntities.length
			pathEntities :+ [child]
		Else
			pathEntities = pathEntities[.. index] + [child] + pathEntities[index ..]
		EndIf

		'set self as parent
		pathEntities[index].SetParent(Self)
	End Method


	Method RemovePathEntity(child:TTowerPathEntity)
		If Not child Then Return
		If Not pathEntities Or pathEntities.length = 0 Then Return

		Local index:Int = 0
		While index < pathEntities.length
			If pathEntities[index] = child
				'skip increasing index, the next child might be also the
				'searched one
				RemovePathEntityAtIndex(index)
			Else
				index :+ 1
			EndIf
		Wend
	End Method


	Method RemovePathEntityAtIndex:Int(index:Int = -1)
		If Not pathEntities Or pathEntities.length = 0 Then Return False

		If index < 0 Then index = pathEntities.length - 1
		'remove parent association (strong reference)
		'this makes it garbage-collectable
		pathEntities[index].SetParent(Null)

		If index <= 0
			pathEntities = pathEntities[1 ..]
		ElseIf index >= pathEntities.length - 1
			pathEntities = pathEntities[.. pathEntities.length-1]
		Else
			pathEntities = pathEntities[.. index] + pathEntities[index+1 ..]
		EndIf

		Return True
	End Method


	Method GetRotationWidth:Int()
		'default: keep the same
		Return frontWidth '_GetEffWidth()
	End Method


	Method _GetEffWidth:Int()
		If level.tower.flatMode
			Return level.tower.COL_WIDTH
		Else
			'first next approach: using the x and xNext is required (+0.5)
			'and a "level.X2ScreenX(colX + COL_WIDTH) - level.X2ScreenX(colX)"
			'is not working properly! (jitters) 
			Return Abs(level.GetTileScreenX(col + 1) - level.GetTileScreenX(col))
		EndIf
	End Method


	'override
	Method GetScreenX:Float()
		Return Int(level.tower.GetScreenX() + level.GetTileScreenX(col) +0.5)
	End Method


	'override
	Method GetBoundingBox:TRectangle()
		If Not boundingBox Then boundingBox = New TRectangle
		boundingBox.Init(area.GetX(), area.GetY(), area.GetW(), area.GetH())
		Return boundingBox
	End Method


	Method Update:Int()
		Super.Update()
		area.SetX( level.GetColX(col) )
		area.SetY( level.GetRowY(row) )
	End Method


	Method RenderPathEntityShadows:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		For Local pathEntity:TTowerPathEntity = EachIn pathEntities
			pathEntity.RenderShadow(xOffset, yOffset, alignment)
		Next
	End Method


	Method RenderPathEntities:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		For Local pathEntity:TTowerPathEntity = EachIn pathEntities
			pathEntity.Render(xOffset, yOffset, alignment)
		Next
	End Method
	

	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		'for now: ONLY RENDER PATHS
		If tileType <> TTower.TILETYPE_PATH Then Return False

		Local tileOffsetY:Int = 0 '10
		Local y:Int = yOffset + GetTopY()
		Local colX:Int = col * level.tower.COL_WIDTH
		Local x:Int = level.GetTileScreenX(col)
		Local xTowerBrick:Int = level.GetTowerScreenX(col)
		Local xNextTowerBrick:Int = level.GetTowerScreenX(col+1)
		Local xNext:Int
		Local effWidth:Int
		Local effTowerWidth:Int
		If level.tower.flatMode
			effWidth = level.tower.COL_WIDTH
		Else
			xNext = level.GetTileScreenX(col + 1)
			'first next approach: using the x and xNext is required (+0.5)
			'and a "level.X2ScreenX(colX + COL_WIDTH) - level.X2ScreenX(colX)"
			'is not working properly! (jitters) 
			effWidth = Abs(xNext - x)
			effTowerWidth = Abs( xNextTowerBrick - xTowerBrick)
			'angle based approach
			'effWidth:int = floor(cos(abs(angle)) * COL_WIDTH)
		EndIf

		Local angle:Int = level.GetColAngle(col)

		'limit to back or front side?
		'if limitSide = -1 and not level.IsBackSide(angle) then return False
		'if limitSide = +1 and level.IsBackSide(angle) then return False
		
		'brick side only visible on front
		'(backside shows only front side until it is hidden totally)
		If Not level.IsBackSide(angle) And effWidth > 0
if level.debug
	If level.tower.WrappedRectsIntersect(GetBoundingBox().Integerize(), level.player.GetBoundingBox().Integerize())
		SetColor 255,0,0
	ElseIf level.tower.WrappedRectsIntersect(GetBoundingBox().Integerize(), level.player.GetBoundingBox().Grow(1,1,1,1).Integerize())
		SetColor 255,175,175
	EndIf
endif
			GetSpriteFromRegistry("path."+((col Mod 3) +1)).DrawResized(New TRectangle.Init(GetScreenX(), y - tileOffsetY, effWidth, 10))
SetColor 255,255,255
			'render shadow on the tower!
			GetSpriteFromRegistry("path.shadow."+((col Mod 3) +1)).DrawResized(New TRectangle.Init(level.tower.GetScreenX() + xTowerBrick, y+10 - tileOffsetY, effTowerWidth, 5))
		EndIf	
		'show a front of the path?
		'-> front is from "radius Inner" to "radius Outer"-point
		If Not level.tower.flatMode
			Local xPreviousWall:Int = level.GetTowerScreenX(col-1)
			Local angleStart:Int = level.GetColAngle(col, False)
			Local angleNext:Int = level.GetColAngle(col + 1, False)
			Local anglePrevious:Int = level.GetColAngle(col -1, False)


			If Not level.IsRightSide(angle)
				If angleNext < -2
					frontWidth = xNextTowerBrick - xNext
					If frontWidth > 0
						If level.IsBackSide(angle)
							'clip to not draw on the tower
							Local clipRect:TRectangle = New TRectangle.Init(level.tower.GetScreenX() - level.tower.PLATFORM_WIDTH, y - tileOffsetY, level.tower.PLATFORM_WIDTH, 10)
							GetSpriteFromRegistry("path.front.left").DrawResized(New TRectangle.Init(GetScreenX(), y - tileOffsetY, frontWidth, 10), Null, -1, False, clipRect)
						Else
							GetSpriteFromRegistry("path.front.left").DrawResized(New TRectangle.Init(GetScreenX() + effWidth, y - tileOffsetY, frontWidth, 10))
						EndIf
					EndIf
				EndIf
			Else
				If angleStart > 2
					'Local xPrevious:Int = level.X2ScreenX(colX - tower.COL_WIDTH, tower.radiusOuter) + tower.radiusInner + 0.5
					frontWidth =  x - xTowerBrick
					GetSpriteFromRegistry("path.front.right").DrawResized(New TRectangle.Init(GetScreenX() - Abs(frontWidth), y - tileOffsetY, Abs(frontWidth), 10))
					'DrawOval(tower.GetScreenX() + x -2, y-2, 4,4)
					'DrawOval(tower.GetScreenX() + xWall -2, y-4, 4,4)
				EndIf
			EndIf
			if level.debug
				SetColor 210,210,210
				GetBitmapFont().Draw(col+","+row, GetScreenX(), y +2 - tileOffsetY)
			endif
			SetColor 255,255,255
			'GetBitmapFont().Draw(angle, tower.GetScreenX() + x -11, y +2 )
			'GetBitmapFont().Draw(backside, tower.GetScreenX() + x - 18, y +2 )
			'GetBitmapFont().Draw(row+","+GetBottomY(), GetScreenX(), level.Local2ScreenY(GetTopY()))

		EndIf
		'DrawMarkerRectangle(GetScreenX() + (GetBoundingBox().GetX() - area.GetX()) , yOffset + GetBoundingBox().GetY(), GetBoundingBox().GetW()-1, GetBoundingBox().GetH())

		RenderChildren(xOffset, yOffset, alignment)

		RenderPathEntities(xOffset, yOffset, alignment)
	End Method
End Type




Type TTowerPathEntity Extends TTowerEntity
	Field state:Int
	Field stateTime:Long
	Field targetRow:Int = -1
	'limits of effective velocity
	Field velocityLimits:TVec2D
	'velocity added by forces (like wind, gravity...)
	Field velocityForces:TVec2D
	Field acceleration:Float
	Field friction:Float
	Field jumpPower:Float
	Field movement:Int
	Field feetX:Int = 1 'from left
	Field feetX2:Int = 5 'from right

	'750ms for full speed
	Const DEFAULT_ACCELERATION:Float = 0.750
	'200ms to stop
	Const DEFAULT_FRICTION:Float = 0.2
	Const DEFAULT_JUMPPOWER:Float = 20000
	Const DEFAULT_JUMPPOWERSMALL:Float = 6000
	
	Const MOVEMENT_LEFT:Int = 1
	Const MOVEMENT_RIGHT:Int = 2
	Const MOVEMENT_UP:Int = 4
	Const MOVEMENT_DOWN:Int = 8
	Const MOVEMENT_JUMP:Int = 16
	Const MOVEMENT_JUMPING:Int = 32
	Const MOVEMENT_FALLING:Int = 64


	Method New()
		velocityForces = New TVec2D
		velocityLimits = New TVec2D.Init(60, 180)
		friction = velocityLimits.x / DEFAULT_FRICTION
		acceleration = velocityLimits.x / DEFAULT_ACCELERATION
		jumpPower = DEFAULT_JUMPPOWER
	End Method


	Method HasMovement:Int(movementKey:Int)
		Return (movement & movementKey) <> 0
	End Method


	Method SetMovement:Int(movementKey:Int, enable:Int = True)
		If enable
			movement :| movementKey
		Else
			movement :& ~movementKey
		EndIf
	End Method


	Method X2ScreenX:Int()
		Return int(level.X2ScreenX(area.GetX(), level.tower.radiusInner * 1.1)) + level.tower.radiusInner + 0.5
	End Method


	Method IsJumping:Int()
		Return HasMovement(MOVEMENT_JUMP) Or HasMovement(MOVEMENT_JUMPING)
	End Method


	Method GetRow:Int(refresh:Int = False)
		If refresh Or row = -1
			row = level.GetRow(GetBottomY())
		EndIf
		Return row
	End Method


	'override
	Method GetBoundingBox:TRectangle()
		If Not boundingBox Then boundingBox = New TRectangle
		boundingBox.Init(area.GetX() + feetX, area.GetY(), area.GetW() - (feetX + feetX2), area.GetH())
		Return boundingBox
	End Method

	
Rem
	Method StartJumping:Int()
		If IsJumping() Then Return False
		
		SetMovement(MOVEMENT_JUMP, True)

		'store where we were before
		targetRow = GetRow()

		'start jumping
		Print "START area.y="+area.GetY()+"  row="+GetRow()+"  rowY="+ level.GetRowY( GetRow() )
		'TODO: WAITING TIME (animation like "crouching")?
		state :+ STATE_START_JUMPING
		state :| STATE_JUMPING
		stateTime = Time.MillisecsLong()

'		velocityForces.AddY(-160)
'		setVelocity(velocity.x, 160)
	End Method


	Method FinishJumping:Int()
		If targetRow = -1 Then Print "FinishJumping: failing with broken targetRow"
		
		Print "FINISH area.y="+area.GetY()+"  row="+GetRow()+"  rowY="+ level.GetRowY( GetRow() )
		area.SetY( level.GetRowY(targetRow) )
		setVelocity(velocity.x,0)

		targetRow = -1 
		state :~ STATE_JUMPING
	End Method
EndRem
	

	Method IsFalling:Int()
		'TODO: add "falling from block"
		'      so better do a "not state & STATE_CLIMBING" for ladders
'		Return state & STATE_JUMPING And velocity.y < 0
	End Method


	Method GetFeetXOnRightTile:Int()
		Return Max(0, (area.GetX2() - feetX2) - level.GetColX(col+1))
	End Method

	Method GetFeetXOnTile:Int()
		Return Max(0, (area.GetX() + feetX) - level.GetColX(col))
	End Method

	Method GetFeetOnRightTile:Int()
		Return TLevel.WrapValue( (area.GetX2() - feetX2) / TTower.COL_WIDTH, 0, level.tower.cols )
	End Method

	Method GetFeetOnTile:Int()
		Return Max(0, (area.GetX() + feetX) / TTower.COL_WIDTH)
	End Method



	Method Move:Int()
		Local oldMovementLeft:Int = GetVelocity().GetX() < 0
		Local oldMovementRight:Int = GetVelocity().GetX() > 0
		Local oldIsFalling:Int = HasMovement(MOVEMENT_FALLING)
		Local effectiveFriction:Float = friction
		Local effectiveAcceleration:Float = acceleration
		If oldIsFalling Then effectiveFriction :* 0.5
		If oldIsFalling Then effectiveAcceleration :* 0.4
	
		'assume a basic downwards movement ("gravity")
		'2* to make it "snappier"
		Local gravity:Float = 5 * 9.81 * TTower.ROW_HEIGHT
		velocityForces.SetXY(0, gravity)

		'handle left/right movement (accelerate or deaccelerate)
		'currently moving to right?
		If HasMovement(MOVEMENT_RIGHT)
			velocityForces.AddX(+ effectiveAcceleration)
		'was (effectively) moving to right in last frame but no longer
		'moving there? Slightly deaccelerate according to the given friction
		ElseIf oldMovementRight
			velocityForces.AddX(- effectiveFriction)
		EndIf
		
		'similar to RIGHT, do it for LEFT	
		If HasMovement(MOVEMENT_LEFT)
			velocityForces.AddX(- effectiveAcceleration)
		'was (effectively) moving to left in last frame but no longer
		'moving Left? Slightly deaccelerate according to the given friction
		ElseIf oldMovementLeft
			velocityForces.AddX(+ effectiveFriction)
		EndIf


		'handle jumping/falling
		'start jumping (if not already jumping or falling)
		If HasMovement(MOVEMENT_JUMP) And Not HasMovement(MOVEMENT_JUMPING) And Not HasMovement(MOVEMENT_FALLING)
			velocityForces.AddY(-jumpPower)
Print "jump  " + velocityForces.ToString() 
			SetMovement(MOVEMENT_JUMPING)
			stateTime = Time.MillisecsLong()
		EndIf
		
		
		'limit velocity if needed
		If velocityLimits
			velocity.SetX( MathHelper.Clamp(velocity.GetX() + (GetDeltaTime() * velocityForces.GetX()), -velocityLimits.x, velocityLimits.x) )
			velocity.SetY( MathHelper.Clamp(velocity.GetY() + (GetDeltaTime() * velocityForces.GetY()), -velocityLimits.y, velocityLimits.y) )
		EndIf


		'avoid jittering when changing direction
		If oldMovementLeft And velocity.GetX() > 0 Then velocity.SetX(0)
		If oldMovementRight And velocity.GetX() < 0 Then velocity.SetX(0)


'print "bbox: "+GetBoundingBox().ToString() +"  " + GetTopY() +"  " + area.GetY()
Local oldVelocity:TVec2D = velocity.Copy()
		HandleCollisions()
		'velocity might be adjusted now
		Super.Move()
		'print "oldPosX="+oldPosition.GetX()+"  posX="+area.GetX()

Rem
		local xOnRightTile:int = Max(0, area.GetX2() - level.GetColX(col+1))
		local tileDown:TTowerTile = level.tower.GetTile(level.GetCol(area.GetX() + feetX), row-1)
		local tileDownRight:TTowerTile = level.tower.GetTile(level.GetCol(area.GetX() + feetX) + 1, row-1)

		if tileDown or (xOnRightTile and tileDownRight)
			SetMovement(MOVEMENT_FALLING, False)
		else
			SetMovement(MOVEMENT_FALLING, True)
		endif
endrem
		Return True
	End Method


	Method HandleCollisions:Int()
		'set to true so the first iteration takes place
		Local collidedX:Int = True
		Local collidedYTop:Int = True
		Local collidedYBottom:Int = True
		Local iterations:Int = 10

		For Local iteration:Int = 0 Until iterations
			'iterate as long as we found a collision to handle
			If Not (collidedX Or collidedYTop Or collidedYBottom) Then Exit

			'nothing found yet (but it is run at least once now)
			collidedX = False
			collidedYTop = False
			collidedYBottom = False

			
			Local finalMovement:TVec2D = New TVec2D.Init(GetDeltaTime() * velocity.x, GetDeltaTime() * velocity.y )
			Local originalMovement:TVec2D = finalMovement.Copy()
			Local plannedMovement:TVec2D = New TVec2D
		
			Local surroundingElements:TTowerEntity[] = level.tower.tiles  '= GetCollidingEntities(self.GetBoundingBox())


			'loop over all (near) tiles and find a one hitting the entity
			'if it would do this movement
			For Local otherEntity:TTowerEntity = EachIn surroundingElements
				If collidedX Or collidedYTop Or collidedYBottom Then Exit

				Local otherBoundingBox:TRectangle = otherEntity.GetBoundingBox().Integerize() 'round to integer

				'left or right
				If finalMovement.x <> 0
					plannedMovement.x = finalMovement.x
					'ignore y-axis for now
					plannedMovement.y = 0

					Local boundingBox:TRectangle = Self.GetBoundingBox().Copy()
					boundingBox.MoveXY(plannedMovement.x, 0)
					boundingBox.Integerize()
					'attention: do a wrapped intersect check to allow col0 vs col17 checks
					While level.tower.WrappedRectsIntersect(otherBoundingBox, boundingBox)
						If finalMovement.x < 0
							plannedMovement.x :+ 1
							boundingBox.MoveXY(1, 0)
						Else
							plannedMovement.x :- 1
							boundingBox.MoveXY(-1, 0)
						EndIf
					End While
					finalMovement.x = plannedMovement.x
				EndIf

				'up or down
				If finalMovement.y <> 0
					plannedMovement.y = finalMovement.y
					'ignore x-axis now
					plannedMovement.x = 0

					Local boundingBox:TRectangle = Self.GetBoundingBox().Copy()
					boundingBox.MoveXY(0,plannedMovement.y)
					boundingBox.Integerize()
'If Int(area.GetX()) = 575 And otherEntity.col=0 And otherEntity.row=28 Then DebugStop
					While level.tower.WrappedRectsIntersect(otherBoundingBox, boundingBox)
						If finalMovement.y > 0
							plannedMovement.y :- 1
							boundingBox.MoveXY(0,-1)
						Else
							plannedMovement.y :+ 1
							boundingBox.MoveXY(0,+1)
						EndIf
					End While

					finalMovement.y = plannedMovement.y
				EndIf

				'store collision status
				collidedX = Abs(finalMovement.x - originalMovement.x) > 0.01 'avoids jitter-false-detection
				collidedYBottom = finalMovement.y < originalMovement.y And originalMovement.y > 0
				collidedYTop = finalMovement.y > originalMovement.y And originalMovement.y < 0

				'stop jumping when hitting a side wall
				'if collidedX and velocity.y > 0
				'	velocity.SetY(0)
				'	finalMovement.SetY(0)
				'endif
			Next



			'if there was a collisions then apply recalculated speeds/movement
			If collidedYTop Or collidedYBottom
				'area.position.AddY(finalMovement.y)
'				area.position.y = int((area.position.y + finalMovement.y) + 0.5)
				velocity.SetY(0)
				finalMovement.SetY(0)

				If collidedYBottom Then SetMovement(MOVEMENT_JUMPING, False)
			EndIf

			If collidedX
'print area.GetX()
				area.position.AddX(finalMovement.x)
				'area.position.x = int((area.position.x + plannedMovement.x)) ' + finalMovement.x) + 0.5)
				'area.position.x = int(area.position.x +0.5)
'				print area.GetX()+" (boundingX: "+GetBoundingBox().GetX() +")  movement: "+ originalMovement.x+" => " + finalMovement.x
				velocity.SetX(0)
				finalMovement.SetX(0)
print "light jump"
'weitermachen - nur springen, wenn tile nur eine Stufe hoeher
				if not HasMovement(MOVEMENT_JUMPING) or HasMovement(MOVEMENT_FALLING) or HasMovement(MOVEMENT_JUMP)
					SetMovement(MOVEMENT_JUMP, True)
					velocity.SetY(-DEFAULT_JUMPPOWERSMALL * GetDeltaTime())
				endif
			EndIf

			
		'continue with next iteration 
		Next
	End Method


	Method LimitMovement:Int(movement:TVec2D)
		'=== CHECK Y-AXIS (UP/DOWN) ===

		'DOWNWARDS
		If movement.y < 0
			'check down or "rightside of down" - whatever comes first
			Local nextDownTile:TTowerTile = level.tower.GetNextTile(col, row, 0, +1, 1)

			If GetFeetXOnRightTile() > 0
				Local nextDownRightTile:TTowerTile = level.tower.GetNextTile(col+1, row, 0, +1, 1)
				If nextDownRightTile
					If Not nextDownTile
						nextDownTile = nextDownRightTile
					'right one comes earlier?
					ElseIf nextDownRightTile.GetTopY() > nextDownTile.GetTopY()
						nextDownTile = nextDownRightTile
					EndIf
				EndIf
			EndIf

			If nextDownTile
				Local diff:Int = (GetBottomY() - nextDownTile.GetTopY())
'hier weitermachen - schauen wo bottomY() ist, schon auf naechster stufe oder
'noch auf dem boden ...
				Print diff+" " + movement.y +"  nextDownTile.row="+nextDownTile.row+" topy="+nextDownTile.GetTopY()
				If diff <= Abs(movement.y)
					movement.y = -diff
					velocity.SetY( 0 )
					SetMovement(MOVEMENT_FALLING, False)
					SetMovement(MOVEMENT_JUMPING, False)
				EndIf
			EndIf

		'UPWARDS
		'elseif allows direct movement-value-modification in the downwards-check
		ElseIf movement.y > 0
			'check if we hit something with the head
			'head is 2 rows higher than feet, but we just check from
			'feet on - if we stuck in a tile, we have to stop too ;-)

			'check up or "rightside of up" - whatever comes first
			Local nextUpTile:TTowerTile = level.tower.GetNextTile(col, row, 0, -1, 1)

			If GetFeetXOnRightTile() > 0
				Local nextUpRightTile:TTowerTile = level.tower.GetNextTile(col+1, row, 0, -1, 1)
				If nextUpRightTile
					If Not nextUpTile
						nextUpTile = nextUpRightTile
					'right one comes earlier?
					ElseIf nextUpRightTile.GetBottomY() < nextUpTile.GetBottomY()
						nextUpTile = nextUpRightTile
					EndIf
				EndIf
			EndIf

			If nextUpTile
				Local diff:Int = (nextUpTile.GetBottomY() - GetTopY())
				'print diff+" " + movement.y +"  selfTopY="+GetTopY()+"  nextUpTile.row="+nextUpTile.row+" topy="+nextUpTile.GetBottomY()
				If diff <= movement.y
					movement.y = diff
					velocity.SetY( 0 )
					SetMovement(MOVEMENT_FALLING, True)
					SetMovement(MOVEMENT_JUMPING, False)
				EndIf
			EndIf
		EndIf


		'integrate current movement
		area.position.AddXY(0, movement.y)


		'=== CHECK X-AXIS (LEFT/RIGHT) ===
		If movement.x > 0
			'stepping into another tile?
			If GetFeetXOnRightTile() > 0
				'figure is 3 tiles high
				Local feetOnRightTile:Int = GetFeetOnRightTile()
				Local feetOnTile:Int = GetFeetOnTile()
				Local tileRight1:TTowerTile = level.tower.GetTile(feetOnRightTile, row)
				Local tileRight2:TTowerTile = level.tower.GetTile(feetOnRightTile, row+1)
				Local tileRight3:TTowerTile = level.tower.GetTile(feetOnRightTile, row+2)
				Local tileRight:Int = tileRight1 Or tileRight2 Or tileRight3
'if tileRight1 then print "tileRight1.row = " + tileRight1.row
'if tileRight2 then print "tileRight2.row = " + tileRight2.row
'if tileRight3 then print "tileRight3.row = " + tileRight3.row
'print "----"
				Local checkTile:TTowerTile
				'auto jump over lower tile
				If Not checkTile And Not HasMovement(MOVEMENT_JUMPING) Then checkTile =  tileRight1
				'if there is a tile or tile 3 then use them for checks (auto jump)
				If tileRight2 Then checkTile = tileRight2 
				If tileRight3 Then checkTile = tileRight3 
				If checkTile
					Local upAllowed:Int = True
					'only auto jump if there is enough space left on top!
					If checkTile = tileRight1
						If upAllowed
							Local nextUpTile:TTowerTile = level.tower.GetNextTile(feetOnTile, row, 0, -1, 1)
'if nextUpTile then print nextUpTile.GetBottomY() + " self: "+GetTopY()
							If nextUpTile And nextUpTile.GetBottomY() < (GetTopY() + 0*TTower.ROW_HEIGHT)
								'print "uptile forbidden  " + nextUpTile.GetBottomY()+" < "+(GetTopY() + 0*TTower.ROW_HEIGHT) 
								upAllowed = False
							EndIf
						EndIf
						If upAllowed
							'check if there is space enough left to fit "into"
							Local nextUpRightTile:TTowerTile = level.tower.GetNextTile(feetOnRightTile, row+1, 0, -1, 1)
							If nextUpRightTile And nextUpRightTile.GetBottomY() - checkTile.GetTopY() < area.GetH()
								'print "right uptile forbidden   bottomY="+nextUpRightTile.GetBottomY()+"  checkTopY="+checkTile.GetTopY()
								upAllowed = False
							EndIf
						EndIf
					EndIf
					If Not upAllowed
						movement.SetX( 0 )
'						movement.SetX( level.GetColX(feetOnRightTile) - area.GetW() + feetX2 )
'						movement.SetY( 0 )
						velocity.SetX(0)
'						local diff:int = level.GetColX(feetOnRightTile) - area.GetW() + feetX2
'						if diff <= movement.x
'					print feetOnRightTile

					'normal x-axis limit
					Else
						movement.SetX( 0 )
'						movement.SetX( level.GetColX(checkTile.col) - area.GetW() + feetX2 )
						velocity.SetX(0)
					EndIf
					
				EndIf
			EndIf
		EndIf


		'integrate current movement
		area.position.AddXY(movement.x, 0)

		Return True
	End Method

	Method RenderShadow:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		'nothing
	End Method
End Type


Type TTowerTestPathEntity Extends TTowerPathEntity
	Field color:TColor

	Method New()
		color = New TColor.Create(Rand(255), Rand(255), Rand(255))
		'area.SetWH(TTower.ROW_HEIGHT, TTower.ROW_HEIGHT)
	End Method

	
	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		color.SetRGB()
		DrawRect(GetScreenX(), yOffset + GetTopY(), area.GetW(), area.GetH())
		SetColor 255,255,255
		
		DrawMarkerRectangle(GetScreenX(), level.Local2ScreenY(GetTopY()), area.GetW(), area.GetH())
		SetColor 255,255,255
		GetBitmapFont().Draw(GetRow(True), GetScreenX()+1, level.Local2ScreenY(GetTopY())+2)
		
	End Method
End Type




Type TTowerEntity Extends TEntity
	Field sprite:TSprite
	Field col:Int = -1
	Field row:Int = -1
	Field boundingBox:TRectangle


	Method X2ScreenX:Int()
		Return level.X2ScreenX(area.GetX(), level.tower.radiusOuter) + level.tower.radiusInner + 0.5
	End Method


	Method Y2ScreenY:Int()
		Return level.Local2ScreenY(GetTopY())
	End Method
	

	Method IsOnBackSide:Int()
		Return level.IsBackSide( X2Angle() )
	End Method


	Method IsOnRightSide:Int()
		Return level.IsRightSide( X2Angle() )
	End Method


	Method X2Angle:Int()
		Return level.X2Angle(area.GetX())
	End Method


	'override
	Method GetBoundingBox:TRectangle()
		If Not boundingBox Then boundingBox = New TRectangle
		boundingBox.Init(area.GetX(), area.GetY(), area.GetW(), area.GetH())
		Return boundingBox
	End Method


	Method GetCol:Int(refresh:Int = False)
		If refresh Or col = -1
			col = level.GetCol(area.GetX())
		EndIf
		Return col
	End Method


	Method GetRow:Int(refresh:Int = False)
		If refresh Or row = -1
			row = level.GetRow( GetBottomY() )
		EndIf
		Return row
	End Method


	Method GetTopY:Int()
		Return Floor(GetY())
'		return int(GetY() + 0.5)
	End Method


	Method GetBottomY:Int()
		Return Floor(GetY() + area.GetH())
		'return int(GetY() + area.GetH() + 0.5)
	End Method
	

	Method GetScreenX:Float()
		'need to offset when the col is scaled down a bit (eg. on left/right side)
		Return level.tower.GetScreenX() + X2ScreenX() + GetRotationOffsetX()
	End Method


	Method GetRotationWidth:Int()
		'default: keep the same
		Return area.GetW()
	End Method


	Method GetRotationOffsetX:Int()
		If level.tower.flatMode Then Return 0
	End Method


	Method Update:Int()
		'run base entity actions - like movement 
		Local result:Int = Super.Update()

		'refresh new col/row values
		GetCol(True)
		GetRow(True)

		'wrap x around tower
		area.SetX( level.tower.WrapX(area.GetX()) )

		Return result
	End Method
	

	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
'		Local x:Int = xOffset + Int(GetScreenX()+0.5)
		Local x:Int = int(xOffset + GetScreenX() + 0.5)

		If Not level.tower.flatMode
'			if level.GetColAngle(GetCol()
		EndIf
'		print xOffset+"  " + GetScreenX() + "  towerGetScreenX="+level.tower.GetScreenX()+"  x2ScreenX="+X2ScreenX() + "  rotationOffsetX="+GetRotationOffsetX()

		SetColor 0,0,0
			sprite.Draw(x+1, yOffset + GetTopY()+1, -1, ALIGN_LEFT_TOP)
		SetColor 255,255,255
		sprite.Draw(x, yOffset + GetTopY(), -1, ALIGN_LEFT_TOP)
		'GetBitmapFont().Draw(GetCol()+","+GetRow(), x + 15, yOffset + Y2ScreenY() - 10)
	End Method
End Type



Type TPlayer Extends TTowerPathEntity
	Field automove:Int = True


	Method Update:Int()
		SetMovement(MOVEMENT_LEFT, KeyDown(KEY_LEFT))
		SetMovement(MOVEMENT_RIGHT, KeyDown(KEY_RIGHT))
		SetMovement(MOVEMENT_JUMP, KeyHit(KEY_SPACE))
		
		Super.Update()
	End Method


	Method RenderShadow:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		Local x:Int = 162 'int(xOffset + GetScreenX() + 0.5)
		SetColor 0,0,0
'		if HasMovement(MOVEMENT_JUMPING)
			sprite.Draw(x+2, yOffset + GetTopY()+2)
'		else
'			sprite.DrawClipped(New TRectangle.Init(x+2, yOffset + GetTopY()+2, sprite.GetWidth()-2, sprite.GetHeight()-2))
'		endif
	End Method
	

	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
'		Super.Render(xOffset, yOffset, alignment)
		Local x:Int = 162 'int(xOffset + GetScreenX() + 0.5)
		SetColor 255,255,255
		sprite.Draw(x, yOffset + GetTopY(), -1, ALIGN_LEFT_TOP)

		'row start indicator
rem
		SetColor 255,255,200
		DrawRect(GetScreenX()-3, level.Local2ScreenY(level.GetRowY(GetRow())), 3, 1)
		DrawRect(GetScreenX()+area.GetW(), level.Local2ScreenY(level.GetRowY(GetRow())), 3, 1)
		DrawRect(GetScreenX()-3, level.Local2ScreenY(level.GetRowBottomY(GetRow())), 3, 1)
		DrawRect(GetScreenX()+area.GetW(), level.Local2ScreenY(level.GetRowBottomY(GetRow())), 3, 1)
'		DrawMarkerRectangle(GetScreenX(), level.Local2ScreenY(GetTopY()), area.GetW(), area.GetH()-1)
		DrawMarkerRectangle(GetScreenX() + (GetBoundingBox().GetX() - area.GetX()) , level.Local2ScreenY( GetTopY() ), GetBoundingBox().GetW(), area.GetH()-1)
		SetColor 255,150,50
		'DrawRect(GetScreenX() + xOffset+1, Y2ScreenY() + area.GetH() - TTower.ROW_HEIGHT , 3, 3)
		DrawRect(GetScreenX() + xOffset, Y2ScreenY() , 3, 3)
		SetColor 255,255,255
		GetBitmapFont().Draw(Int(GetX())+", "+GetBottomY(), GetScreenX()+20, level.Local2ScreenY(GetTopY())-2)
'		GetBitmapFont().Draw(GetBottomY(), GetScreenX()+25, level.Local2ScreenY(GetTopY())-2)
		'GetBitmapFont().Draw(GetRow(true), GetScreenX()+1, level.Local2ScreenY(GetTopY())+2)

		'GetBitmapFont().Draw(int(GetX()), GetScreenX() + xOffset + 10, Y2ScreenY()-30)
		GetBitmapFont().Draw(GetFeetOnTile()+"\|"+GetFeetOnRightTile()+", "+GetRow(), GetScreenX() + xOffset + 20, Y2ScreenY() + 5)
		'GetBitmapFont().Draw("y="+int(GetY()), GetScreenX() + xOffset + 20, Y2ScreenY() + 12)

endrem
	End Method
End Type




Type TCamera Extends TEntity
	Field target:TEntity
	Field positionLimit:TRectangle
	

	Method New()
		Reset()
	End Method


	Method SetParent:Int(parent:TRenderableEntity)
		'constrain position
		If parent
			positionLimit = New TRectangle.Init(-1, 0, -1, parent.GetHeight())
		EndIf

		Return Super.SetParent(parent)
	End Method
	

	Method Reset:Int()
		If target
			SetPosition(target.area.GetX(), target.area.GetY())
		EndIf
		SetVelocity(0,0)
	End Method


	Method Update:Int()
		Super.Update()

		'move to target
		If target
			'center to target
			SetPosition(int(target.area.position.x), (target.area.GetYCenter() - 0.5*area.GetH()))
			'limit to position
			If positionLimit
				area.position.y = Min(area.position.y, positionLimit.GetY2() - APP_HEIGHT)
			EndIf
			
'			SetVelocity(target.velocity.x, target.velocity.y)
		EndIf
	End Method
End Type



Function DrawMarkerRectangle(x:Int, y:Int, w:Int, h:Int, r:Int=255, g:Int=100, b:Int=0)
	'top
	SetColor r,g,b
	'drawline is offset somehow with virtual resolution
	'DrawLine(x, y, x, y + 5)
	'DrawLine(x + w - 5, y, x + w, y)
	'DrawLine(x + w, y, x + w, y + 5)
	'-> using rects
	DrawRect(x, y, 5, 1)
	DrawRect(x, y, 1, 5)
	DrawRect(x + w - 5, y, 5, 1)
	DrawRect(x + w, y, 1, 5)
	'bottom
	DrawRect(x, y + h, 5, 1)
	DrawRect(x, y + h - 5, 1, 5)
	DrawRect(x + w - 5, y + h, 5, 1)
	DrawRect(x + w, y + h - 5, 1, 5)
	SetColor 255,255,255
End Function