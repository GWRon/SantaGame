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
'Import "../source/external/Render2Texture/renderimage.bmx"

'TODO: use render2texture as VirtualResolution is ignored on pixmap scaling

global multi:int = 2
global g:TGraphics = Graphics(320*multi, 200*multi, 0)
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


Global level:TLevel = New TLevel

Const APP_WIDTH:Int = 320
Const APP_HEIGHT:Int = 200

'global renderImage:TRenderImage = CreateRenderImage(TGraphicsManager._g, 320, 200)
'global renderImage:TRenderImage = CreateRenderImage(g, 320, 200)
While Not KeyDown(key_escape)
	Level.Update()

	If KeyHit(KEY_F)
		level.tower.SetFlatMode(1 - level.tower.flatMode)
	EndIf

	cls
	Level.Render()

rem
'	GetGraphicsManager().ResetVirtualGraphicsArea()
'	SetRenderImage(renderImage)
'		cls
		Level.Render()
'	SetRenderImage(Null)
'	GetGraphicsManager().SetupVirtualGraphicsArea()

	if renderImage
		SetScale 2,2
		renderImage.flags = DYNAMICIMAGE
		DrawImage(renderImage,0,0)
		SetScale 1,1
	endif
endrem
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

	'raise the tower by this
	Global GROUND_HEIGHT:Int = 10


	Method New()
		tower = New TTower.Init(18, 70)
		If Not tower.flatMode
			tower.area.SetXY(70,0)
		EndIf

		player = New TPlayer
		camera = New TCamera
		camera.SetParent(tower)
		camera.target = player

		player.SetPosition(tower.Col2X(0.5), tower.Row2Y(0))
		player.area.SetWH(40, 20)


		For Local i:Int = 0 Until 64
			starsX[i] = Rand(0, 320)
			starsY[i] = Rand(0, 200)
		Next
	End Method


	Method Reset:Int()
	End Method


	Method Init()
	End Method


	Function Lerp:Float(v:Float, addPerSecond:Float, dt:Float)
		 Return v + (addPerSecond * dt)
	End Function


	Function WrapValue:Float(v:Float, vMin:Float, vMav:Float)
		If v < vMin
			Return vMav - (vMin - v) Mod (vMav - vMin)
		Else
			Return vMin + (v - vMin) Mod (vMav - vMin)
		EndIf
	End Function


	'transform tower-x-coord to screen coord
	Method X2ScreenX:Float(x:Float, radius:Int=-1)
		x :- camera.GetX()
'		x = floor(x)

		If Not tower.flatMode
			If radius = -1 Then radius = tower.radiusInner
			Return radius * Sin((tower.WrapX(x) / Float(tower.GetWidth()) * 180.0/Pi) * 2.0 * Pi)
		Else
			x = tower.WrapX(x)
			If (x > (tower.GetWidth()/2.0))
				x = -(tower.GetWidth() - x)
				'mirroring needs a odd number (1-2--3--2-1 vs 1--2-2--1)
'				if tower.GetWidth() mod 2 = 0 then x :- 1
			EndIf
			'avoid border-flickering on the most left bricks
'			if (x < -190) 'TODO: why 190?
'			if (x < -150) 'TODO: why 190?
'				x :+ 0
'			endif
			If x < 0 - tower.radiusInner
				x :- 1
			EndIf
			Return x
		EndIf
	End Method


	'transform tower-y-coord to screen coord
	Method Y2ScreenY:Float(y:Float)
		Return tower.GetHeight() - GROUND_HEIGHT - (tower.GetY() - camera.area.GetY())
	End Method
	

	'transform local y to renderY
	Method TransformY:Float(y:Float)
		Return APP_HEIGHT - GROUND_HEIGHT - tower.ROW_HEIGHT - (y - camera.area.GetY())
	End Method
	

	Method RenderMapTiles(colMin:Int, colMax:Int, direction:Int, limitSide:Int = 0)
		Local rowMin:Int = Max(0, tower.Y2Row(camera.area.GetY() - GROUND_HEIGHT) - 1)
		Local rowMax:Int = Min(tower.rows - 1, rowMin + (APP_HEIGHT / tower.ROW_HEIGHT + 1))
		Local cell:Int
		Local col:Int = colMin

		While col <> colMax
			For Local row:Int = rowMin To rowMax
				Local y:Int = TransformY(row * tower.ROW_HEIGHT)

				Local tileType:Int = tower.GetTile(col, row)
				If tileType = TTower.TILETYPE_PATH
					Local colX:Int = col * tower.COL_WIDTH
					Local x:Int = level.X2ScreenX(colX, tower.radiusOuter) + tower.radiusInner + 0.5
					Local xTower:Int = level.X2ScreenX(colX, tower.radiusInner) + tower.radiusInner + 0.5
					Local xNext:Int
					Local effWidth:Int
					Local effTowerWidth:Int
					Local frontWidth:Int '0
					If tower.flatMode
						effWidth = tower.COL_WIDTH
						
					Else
						xNext = level.X2ScreenX(colX + tower.COL_WIDTH, tower.radiusOuter) + tower.radiusInner + 0.5
						'first next approach: using the x and xNext is required (+0.5)
						'and a "level.X2ScreenX(colX + COL_WIDTH) - level.X2ScreenX(colX)"
						'is not working properly! (jitters) 
						effWidth = Abs(xNext - x)
						effTowerWidth = Abs(level.X2ScreenX(colX + tower.COL_WIDTH, tower.radiusInner) + tower.radiusInner + 0.5 - xTower)
						'angle based approach
						'effWidth:int = floor(cos(abs(angle)) * COL_WIDTH)
					EndIf

					Local angle:Int = level.WrapValue( tower.X2Angle(colX + 0.5 * tower.COL_WIDTH) - tower.X2Angle(level.camera.area.GetX()), -180, 180)
					Local backSide:Int = angle <= -90 Or angle >= 90
					Local rightSide:Int = angle > 0

					'limit to back or front side?
					if limitSide = -1 and not backSide then continue
					if limitSide = +1 and backSide then continue
					
'	if not tower.flatMode and not MathHelper.inInclusiveRange(angle, -90, 90) then continue

					'brick side only visible on front
					'(backside shows only front side until it is hidden totally)
					If Not backside And effWidth > 0
						GetSpriteFromRegistry("path."+((col Mod 3) +1)).DrawResized(New TRectangle.Init(tower.GetScreenX() + x, y, effWidth, 10))
						'render shadow on the tower!
						GetSpriteFromRegistry("path.shadow."+((col Mod 3) +1)).DrawResized(New TRectangle.Init(tower.GetScreenX() + xTower, y+10, effTowerWidth, 5))
					EndIf	
					'show a front of the path?
					'-> front is from "radius Inner" to "radius Outer"-point
					If Not tower.flatMode
						Local xNextWall:Int = level.X2ScreenX(colX + tower.COL_WIDTH, tower.radiusInner) + tower.radiusInner + 0.5
						Local xPreviousWall:Int = level.X2ScreenX(colX - tower.COL_WIDTH, tower.radiusInner) + tower.radiusInner + 0.5
						Local xWall:Int = level.X2ScreenX(colX, tower.radiusInner) + tower.radiusInner + 0.5
						Local angleStart:Int = level.WrapValue( tower.X2Angle(colX) - tower.X2Angle(level.camera.area.GetX()), -180, 180)
						Local angleNext:Int = level.WrapValue( tower.X2Angle(colX + tower.COL_WIDTH) - tower.X2Angle(level.camera.area.GetX()), -180, 180)
						Local anglePrevious:Int = level.WrapValue( tower.X2Angle(colX - tower.COL_WIDTH) - tower.X2Angle(level.camera.area.GetX()), -180, 180)


						If angle < 0 And angle >= -180
							If angleNext < -2
								Local xNextWall:Int = level.X2ScreenX(colX + tower.COL_WIDTH, tower.radiusInner) + tower.radiusInner + 0.5
								frontWidth = xNextWall - xNext
								If frontWidth > 0
									If backSide
										'clip to not draw on the tower
										Local clipRect:TRectangle = New TRectangle.Init(tower.GetScreenX() - tower.PLATFORM_WIDTH, y, tower.PLATFORM_WIDTH, 10)
										GetSpriteFromRegistry("path.front.left").DrawResized(New TRectangle.Init(tower.GetScreenX() + x, y, frontWidth, 10), Null, -1, False, clipRect)
									Else
										GetSpriteFromRegistry("path.front.left").DrawResized(New TRectangle.Init(tower.GetScreenX() + x + effWidth, y, frontWidth, 10))
									EndIf
								EndIf
							EndIf
						Else
							If angleStart > 2
								'Local xPrevious:Int = level.X2ScreenX(colX - tower.COL_WIDTH, tower.radiusOuter) + tower.radiusInner + 0.5
								frontWidth =  x - xWall
								GetSpriteFromRegistry("path.front.right").DrawResized(New TRectangle.Init(tower.GetScreenX() + x - Abs(frontWidth), y, Abs(frontWidth), 10))
								'DrawOval(tower.GetScreenX() + x -2, y-2, 4,4)
								'DrawOval(tower.GetScreenX() + xWall -2, y-4, 4,4)
							EndIf
						EndIf
'						GetBitmapFont().Draw(angle, tower.GetScreenX() + x -11, y +2 )
'						GetBitmapFont().Draw(backside, tower.GetScreenX() + x - 18, y +2 )
					EndIf
					
				


Rem

					local x:int = col * tower.COL_WIDTH
					'attention: use _center_ of the tile
					local angle:int = WrapValue(tower.X2Angle(x + 0.5 * tower.PLATFORM_WIDTH, tower.radiusOuter) - tower.X2Angle(camera.area.GetX(), tower.radiusOuter), -180, 180)
					'if tower.flatMode then angle = 0



					'local angle:int = level.WrapValue(X2Angle(x) - X2Angle(level.camera.area.GetX()), -180, 180)
					local screenX:int = level.X2ScreenX(x, tower.radiusOuter) + tower.radiusInner + 0.5

if not tower.flatMode and not MathHelper.inInclusiveRange(angle, -90, 90) then continue

					if tower.flatMode or MathHelper.inInclusiveRange(angle, 0, 180)
						'add col_width as the cols are centered too

						SetColor 0,0,0
'						DrawRect(x + 1*tower.PLATFORM_WIDTH/2, y, tower.PLATFORM_WIDTH, 12)
						SetColor 0 + (col mod 2)*100,50,100
'						DrawRect(x + 1*tower.PLATFORM_WIDTH/2 +1, y +1, tower.PLATFORM_WIDTH -2, 12-2)
						SetColor 255,255,255
						DrawOval(tower.GetScreenX() + screenX -5, y + 5, 10, 10)

						GetBitmapFont().Draw(angle, x + 1*tower.PLATFORM_WIDTH/2 +3, y +3)
					endif
endrem
				EndIf

Rem
			
				'calculate screen coords
				local x:int = TransformY(row * tower.ROW_HEIGHT)
				local y:int = tower.Col2X(col)
hier weitermachen
				'skip invisible ones
				if y + tower.ROW_HEIGHT < 0 or y > APP_HEIGHT then continue

				DrawRect(x,y, 10,10)

				'TODO
				'local tile:TEntity = tower.GetTile(col, row)
				'handle tile
endrem
			Next
			col = tower.WrapCol(col + direction)
		Wend

	End Method


	Method RenderBackground_Stars()
		Local startX:Int = WrapValue(APP_WIDTH  * camera.GetX()/Float(tower.GetWidth()), 0, APP_WIDTH)
		Local startY:Int = WrapValue(APP_HEIGHT * camera.GetY()/Float(tower.GetHeight()), 0, APP_HEIGHT)
		Local negativeX:Int = APP_WIDTH - startX 
		Local negativeY:Int = APP_HEIGHT - startY
		SetColor 255,255,255
		For Local i:Int = 0 Until 64
			'wrap around rotating axis
			Local starX:Int = WrapValue(startX + starsX[i], 0, APP_WIDTH)
			DrawRect(starX, startY + starsY[i], 1,1)
		Next
	End Method


	Method RenderBackground()
		RenderBackground_Stars()
	
		Local l:Int = tower.X2Col(camera.area.GetX() - tower.GetWidth()/4.0)
		Local r:Int = tower.X2Col(camera.area.GetX() + tower.GetWidth()/4.0)

		'render parts of the map left and right of the tower
		RenderMapTiles(tower.WrapCol(l - 1), tower.WrapCol(l + 1), +1, -1)
		RenderMapTiles(tower.WrapCol(r + 2), tower.WrapCol(r - 1), -1, -1)

'		RenderMapTiles(15,0, -1)
	End Method


	Method RenderForeground()
		Local l:Int = tower.X2Col(camera.area.GetX() - tower.GetWidth()/4.0)
		Local c:Int = tower.X2Col(camera.area.GetX())
		Local r:Int = tower.X2Col(camera.area.GetX() + tower.GetWidth()/4.0)

		'render parts of the map left and right of the tower
		RenderMapTiles(l, tower.WrapCol(c    ), +1, +1)
		RenderMapTiles(r, tower.WrapCol(c - 1), -1, +1)


		'draw ground _after_ tower, so a "tower in destruction" can move
		'downwards without trouble
		SetColor 255,255,255
		Local startOffset:Int = camera.area.GetX()
		Local groundSprite:TSprite = GetSpriteFromRegistry("ground")
		groundSprite.TileDrawHorizontal(-startOffset Mod groundSprite.GetWidth(), APP_HEIGHT, APP_WIDTH + groundSprite.GetWidth(), ALIGN_LEFT_BOTTOM)
	End Method


	Method RenderDebug()
		Local startX:Int = WrapValue(APP_WIDTH  * camera.GetX()/Float(tower.GetWidth()), 0, APP_WIDTH)
		Local startY:Int = WrapValue(APP_HEIGHT * camera.GetY()/Float(tower.GetHeight()), 0, APP_HEIGHT)
		SetColor 255,0,0
		GetBitmapFont().DrawStyled("start: x="+startX+" y="+startY, 0,0, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("camera: x="+Int(camera.GetX())+" y="+Int(camera.GetY())+"  rx="+Int(camera.area.GetX()), 0,7, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("tower: w="+Int(tower.GetWidth())+" h="+Int(tower.GetHeight())+" cols="+tower.cols+" rows="+tower.rows, 0,14, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("player: x="+Int(player.GetX())+" y="+Int(player.GetY())+" rx="+Int(player.area.GetX()), 0,21, Null, TBitmapFont.STYLE_SHADOW, 1, 2.0)

		SetColor 255,255,255
	End Method
	

	Method Update:Int()
		player.Update()

		camera.Update()
	End Method


	Method Render:Int()
		tower.render(x, y)

		'=== RENDER ===
		'adjust interpolation
		Local dt:Float = GetDeltaTimer().GetTween()
		player.area.position.x = Tower.WrapX(player.GetX() + TInterpolation.Linear(0, player.velocity.GetX(),  dt, 1.0))
		player.area.position.y = player.GetY() + TInterpolation.Linear(0, player.velocity.GetY(),  dt, 1.0)
		camera.area.position.x = tower.WrapX(player.GetX() + TInterpolation.Linear(0, player.velocity.GetX(),  dt, 1.0))
		camera.area.position.y = camera.GetY() + TInterpolation.Linear(0, camera.velocity.GetY(),  dt, 1.0)

		'limit tweened position
		player.area.position.y = Max(0, player.area.position.y)
		camera.area.position.y = Max(0, camera.area.position.Y)

		RenderBackground()

		tower.Render()

		RenderForeground()

		RenderDebug()
	End Method
End Type



Type TTower Extends TEntity

	Field tiles:Int[]
	Field cols:Int
	Field rows:Int
	Field radiusInner:Int
	Field radiusOuter:Int

	'show 3d or 2d tower?
	Global flatMode:Int = False
	Global debugView:Int = False

	Global COL_WIDTH:Int = 32 '31 '27
	Global ROW_HEIGHT:Int = 33 '27
	Global ROW_SURFACE:Int = 12 '3
	Global PLATFORM_WIDTH:Int = 0

	Const TILETYPE_GROUND:Int = -1
	Const TILETYPE_AIR:Int = 0
	Const TILETYPE_PATH:Int = 1

	
	Method Init:TTower(cols:Int, rows:Int)
		Self.cols = cols
		Self.rows = rows
		tiles = New Int[cols * rows]
		area.SetWH(cols * COL_WIDTH, rows  * ROW_HEIGHT)

		SetFlatMode(False)

		Local map:String
		map :+ "xxx  xxxxx  xxxxxx~n"
		map :+ "        xx  xxxxxx~n"
		map :+ "xxx  xxxxx  xxxxxx~n"
		map :+ "xxx  xxxxx  xxxxxx~n"
		map :+ "xxx  xxxxx  xxxxxx~n"
		map :+ "        xx  xxxxxx~n"
		map :+ "        xx  xxxxxx~n"
		map :+ "        xx  xxxxxx~n"
		map :+ "xxx  xxxxx  xxxxxx~n"
		map :+ "xxx  xxxxx  xxxxxx~n"
		map :+ "xxx  xxxxx  xxxxxx~n"
		map :+ "xxx  xxxxx  xxxxxx~n"
		map :+ "    xx   x        ~n"
		map :+ "  xx    x         ~n"
		map :+ "xx     x     xx   "

		InitTilesFromString(map)
		
		
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

		'process from bottom to top
		For Local lineNumber:Int = lines.length-1 To 0 Step -1
			Local line:String = lines[lineNumber]
			lineIndex = 0
			For Local i:Int = 0 Until line.length
				Local tileType:Int = 0
				If line[i] = Asc("x") Then tileType = 1

				tiles[index + lineIndex] = tileType
				lineIndex :+ 1
			Next
			index :+ mapWidth
		Next
	End Method


	'=== HELPER ===

	'wrap x coord within tower limits
	Method WrapX:Float(x:Float)
		Return TLevel.WrapValue(x, 0, area.GetW())
	End Method


	'wrap column  around to stay within tower boundary
	Method WrapCol:Float(col:Float)
		Return TLevel.WrapValue(col, 0, cols)
	End Method


	'convert x coord to column number
	Method X2Col:Int(x:Float)
		Return Int(WrapX(x) / COL_WIDTH)
	End Method


	'convert y coord to row number
	Method Y2Row:Int(y:Float)
		Return Int(y / ROW_HEIGHT)
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
	Method X2Angle:Float(x:Float, radius:Int = -1)
		If radius = -1 Then radius = area.GetW()/2
		Return 360.0 * (WrapX(x) / (2*radius))
	End Method


	'returns whether an x coord is near a column's center
	Method IsNearColumnCenter:Int(x:Float, column:Int, limit:Int)
		Return limit > Abs(x - Col2X(column + 0.5)) / ( COL_WIDTH / 2.0)
	End Method


	'returns whether a y coord is near the surface of a row
	Method IsNearRowSurface:Int(y:Float, row:Int)
		Return y > (Row2Y(row + 1) - ROW_SURFACE)
	End Method


	Method GetTile:Int(col:Int, row:Int)
		If row < 0
			Return TILETYPE_GROUND
		ElseIf row >= rows
			Return 0;
			Return TILETYPE_AIR
		Else
			Return tiles[row * cols + col ]
		EndIf
	End Method


	Method RenderBricks:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		'offset tiles/bricks every odd/even row
'		local offsets:Float[] = [0.0, 0.30, 0.6, 1.2]
		Local offsets:Float[] = [0.0]
		Local offset:Int = 0

		For Local row:Int = 0 Until rows
			Local rowY:Int = level.TransformY( row * ROW_HEIGHT)
			'visible?
			If MathHelper.inInclusiveRange(rowY, -ROW_HEIGHT, APP_HEIGHT - level.GROUND_HEIGHT)
				RenderBrickRow(rowY, offsets[offset], xOffset, yOffset)
			EndIf
			offset = (offset + 1) Mod offsets.length
		Next
	End Method


	Method RenderBrickRow(y:Float, offset:Float, xOffset:Float = 0, yOffset:Float = 0)
		RenderBrickRow_JITTERING(y, offset, xOffset, yOffset)
		'RenderBrickRow_JITTERCORRECTED(y, offset, xOffset, yOffset)
	End Method


	Method RenderBrickRow_JITTERING(y:Float, offset:Float, xOffset:Float = 0, yOffset:Float = 0)
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
			If Not flatMode And Not MathHelper.inInclusiveRange(angle, -90, 90) Then Continue

			GetSpriteFromRegistry("wall."+((col Mod 3) +1)).DrawResized(New TRectangle.Init(GetScreenX() + x, y, effWidth, ROW_HEIGHT))
			'DrawOval(GetScreenX() + x-5, 130, 10, 10)
			'GetBitmapFont().Draw(x, GetScreenX() + x + 5, y + 5)
		Next
	End Method

	
	Method RenderBrickRow_JITTERCORRECTED(y:Float, offset:Float, xOffset:Float = 0, yOffset:Float = 0)
		Local x:Int
		Local angle:Float
		Local effWidth:Int

		Local mostLeft:Int = 0
		Local mostLeftX:Int = 10000
		Local visible:Int[] = New Int[cols]
		Local widths:Int[] = New Int[cols]
		Local startXs:Int[] = New Int[cols]
		Local mostCenter:Int = 0
		Local mostCenterDistance:Int = 10000

		For Local col:Int = 0 Until cols
			x = (col + offset) * COL_WIDTH
			'attention: use _center_ of the tile
			angle = level.WrapValue(X2Angle(x + 0.5 * COL_WIDTH) - X2Angle(level.camera.area.GetX()), -180, 180)
			If flatMode Then angle = 0

			If flatMode Or MathHelper.inInclusiveRange(angle, -95, 95)
				visible[col] = True
			EndIf

			x = level.X2ScreenX(x) + radiusInner + 0.5

'if y=114 then print "col"+col+"  x=" + x +"   angle:" + level.WrapValue(int(angle), 0, TOWER_ANGLES-1)
			If angle = 90
				effWidth = 0
			ElseIf angle = 0
				effWidth = COL_WIDTH
			Else
				effWidth = Floor(Cos(Abs(angle)) * COL_WIDTH)
			EndIf

			If effWidth <= 0
				visible[col] = False
				Continue
			EndIf


			widths[col] = effWidth
			startXs[col] = x


			If mostLeftX > x
				mostLeft = col
				mostLeftX = x
			EndIf
		
			If mostCenterDistance > Abs(x + 0.5 * COL_WIDTH - radiusInner)
				mostCenter = col
				mostCenterDistance = Abs(x + 0.5 * COL_WIDTH - radiusInner)
			EndIf
		Next


		'check for too big gaps
'rem
		Local totalWidth:Int = 2*radiusInner
		Local reachedWidth:Int = 0
		For Local col:Int = mostLeft Until cols + mostLeft
			Local colIndex:Int = col Mod cols
			If Not visible[colIndex] Then Continue
			reachedWidth :+ widths[colIndex]
		Next

		'start the most left when in rotating-tower-mode
		If Not flatMode Then startXs[mostLeft] = 0

		Local addWidth:Int = Max(0,(totalWidth - reachedWidth))
		Local widthAccumulator:Float = 0.0
		For Local col:Int = mostLeft Until cols + mostLeft
			Local colIndex:Int = col Mod cols
			If Not visible[colIndex] Then Continue

			Local nextColIndex:Int = (colIndex +1) Mod cols
			'nothing adjustable coming
			If Not visible[nextColIndex] Then Continue

			'increase width
			widthAccumulator :+ widths[colIndex] / Float(totalWidth) * addWidth
			If widthAccumulator >= 1.0
				widths[colIndex] :+ 1
				widthAccumulator :- 1
			EndIf


			startXs[nextColIndex] = startXs[colIndex] + widths[colIndex]

			'limit width
'			if startXs[nextColIndex] + widths[nextColIndex] > radiusInner
'				widths[nextColIndex] = 2*radiusInner - startXs[nextColIndex]
'			endif
		Next
'endrem

		Local lastX2:Int
		For Local col:Int = 0 Until cols
			If Not visible[col] Then Continue
			
			If debugView 'or 1 = 1
'				SetColor 0,0,0
				SetColor 0,(col Mod 2)*150,(1-(col Mod 2))*150
				DrawRect(GetScreenX() + startXs[col], y, widths[col], ROW_HEIGHT)
				SetColor 255,150,0
				DrawRect(GetScreenX() + startXs[col]+1, y+1, Max(1,widths[col]-2), ROW_HEIGHT-2)
				SetColor 0,0,0
				GetBitmapFont().Draw("X"+x, GetScreenX() + startXs[col], y+3)
				SetColor 255,255,255
			Else
				'GetSpriteFromRegistry("wall."+(col mod 3 +1)).Draw(GetScreenX() + startXs[col], y)
				GetSpriteFromRegistry("wall."+((col Mod 3) +1)).DrawResized(New TRectangle.Init(GetScreenX() + startXs[col], y, widths[col], ROW_HEIGHT))
Rem
				'drawimage
				SetColor 50 + (col mod 2)*200,(1 - col mod 2)*200,0
				DrawRect(GetScreenX() + startXs[col], y, Max(1,widths[col]), ROW_HEIGHT*0.5)

				SetColor 255,150,0
				DrawRect(GetScreenX() + startXs[col]+1, y+1, Max(1,widths[col]-2), ROW_HEIGHT-2)
				SetColor 255,255,255
endrem
			EndIf
		Next
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		Local top:Int = Max(0, level.TransformY(GetHeight()))
		Local bottom:Int = Min(APP_HEIGHT, level.TransformY(0) + level.tower.ROW_HEIGHT)

		If Not flatMode
			Local vpX:Int, vpY:Int, vpH:Int, vpW:Int
			GetViewport(vpX, vpY, vpW, vpH)
'print "vpX="+vpX+"  vpY="+vpY+"  vpH="+vpH+"  vpW="+vpW
			'SetViewport(GetScreenX(), top, radiusInner*2-1, bottom-top)

			'render background
			SetColor 0,0,0
			DrawRect(GetScreenX(), top, radiusInner*2, bottom - top)
			SetColor 255,255,255

			RenderBricks(xOffset, yOffset, alignment)

			SetViewport(vpX, vpY, vpW, vpH)
		Else
			RenderBricks(xOffset, yOffset, alignment)
		EndIf


		rem
		For Local x:Int = 0 To 546 Step 32
			Local angle:Int = level.WrapValue(X2Angle(x) - X2Angle(level.camera.area.GetX()), -180, 180)
			Local screenX:Int = level.X2ScreenX(x) + radiusInner + 0.5
			If Not flatMode And Not MathHelper.inInclusiveRange(angle, -90, 90)
				SetBlend Alphablend
				SetAlpha 0.25
			EndIf
			SetColor 255 - (x / 32) * 25, 0,255
			DrawOval(GetScreenX() + screenX-5, 100, 10, 10)
			SetBlend MaskBlend
			SetAlpha 1.0
		Next

		'outer ring
		For Local x:Int = 0 To 546 Step 32
			Local angle:Int = level.WrapValue(X2Angle(x) - X2Angle(level.camera.area.GetX()), -180, 180)
			Local screenX:Int = level.X2ScreenX(x, radiusOuter) + radiusInner + 0.5
			If Not flatMode And Not MathHelper.inInclusiveRange(angle, -90, 90)
				SetBlend Alphablend
				SetAlpha 0.25
			EndIf
			SetColor 255 - (x / 32) * 25, 0,255
			DrawOval(GetScreenX() + screenX-7, 120, 14, 14)
			SetBlend MaskBlend
			SetAlpha 1.0
			SetColor 255,255,255
			If  flatMode Or MathHelper.inInclusiveRange(angle, -90, 90)
				GetBitmapFont().Draw(screenX, GetScreenX() + screenX-8, 120+2)
			EndIf
			If x = 0
				GetBitmapFont().Draw("x="+screenX, 5, 84 + 50)
				GetBitmapFont().Draw("a="+angle, 5, 92 + 50)
			EndIf
			If x = 32
				GetBitmapFont().Draw("x="+screenX, 40, 84 + 50 )
				GetBitmapFont().Draw("a="+angle, 40, 92 + 50)
			EndIf
		Next
		endrem

Rem
			local colX:int = (col + offset) * COL_WIDTH
			local x:int = level.X2ScreenX(colX) + radiusInner + 0.5
			local xNext:int = level.X2ScreenX(colX + COL_WIDTH) + radiusInner + 0.5
			'first next approach: using the x and xNext is required (+0.5)
			'and a "level.X2ScreenX(colX + COL_WIDTH) - level.X2ScreenX(colX)"
			'is not working properly! (jitters) 
			local effWidth:int = xNext - x
			'angle based approach
			'local effWidth:int = floor(cos(abs(angle)) * COL_WIDTH)

			'skip negative or invisible walls (like front to background)
			if effWidth <= 0 then continue

			local angle:int = level.WrapValue( X2Angle(colX + 0.5 * COL_WIDTH) - X2Angle(level.camera.area.GetX()), -180, 180)
			if not flatMode and not MathHelper.inInclusiveRange(angle, -90, 90) then continue
endrem
		SetColor 255, 255, 255
    End Method
End Type




Type TPlayer Extends TEntity
	Field automove:Int = True

	Method Update:Int()
		Local dx:Float = 0
		Local dy:Float = 0

		automove = False
		If KeyDown(KEY_LALT) Then automove = True

		If automove
			dx = -60
		Else
			If KeyDown(key_left) Then
				dx = -40
			End If
			
			If KeyDown(key_right) Then
				dx = +40
			End If
		EndIf

		If KeyHit(KEY_SPACE) Then area.position.x :- 1

'		If KeyHit(key_left) Then area.position.x :-1
'		If KeyHit(key_right) Then area.position.x :+1

		area.position.x = level.tower.WrapX(area.position.x + GetDeltaTime() * dx)
		area.position.y :+ GetDeltaTime() * dy
		'todo: jump/fall
	End Method
End Type




Type TCamera Extends TEntity
	Field target:TEntity
	Field positionLimit:TRectangle
	

	Method New()
		Reset()
	End Method


	Method Reset:Int()
		If target
			SetPosition(target.area.GetX(), target.area.GetY())
		EndIf
		SetVelocity(0,0)

		'constrain position
		If parent
			positionLimit = New TRectangle.Init(-1, 0, -1, parent.GetHeight())
		EndIf
	End Method


	Method Update:Int()
		Super.Update()

		'move to target
		If target
			SetPosition(target.area.position.x, target.area.position.y)
			SetVelocity(target.velocity.x, target.velocity.y)
		EndIf
	End Method
End Type