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

'TODO: use render2texture as VirtualResolution is ignored on pixmap scaling

Graphics 640, 400, 0
SetVirtualResolution(320,200)

TBitmapFontManager._defaultFlags = 0 'unset SMOOTHFONT
GetBitmapFontManager().Add("default", "../assets/gfx/fonts/slkscr.ttf", 8, 0)

Local registryLoader:TRegistryLoader = New TRegistryLoader
registryLoader.baseURI = "../"
registryLoader.LoadFromXML("config/assets.xml", True)


global level:TLevel = new TLevel

Const APP_WIDTH:int = 320
Const APP_HEIGHT:int = 200


While Not KeyDown(key_escape)
	Level.Update()

	if KeyHit(KEY_F)
		level.tower.SetFlatMode(1 - level.tower.flatMode)
	endif
	
	Cls
	Level.Render()
	Flip 1
Wend




Type TLevel
	Field tower:TTower
	Field player:TPlayer
	Field camera:TCamera
	Field x:int
	Field y:int
	Field starsX:int[64]
	Field starsY:int[64]

	'raise the tower by this
	Global GROUND_HEIGHT:int = 10


	Method New()
		tower = New TTower.Init(18, 70)
		if not tower.flatMode
			tower.area.SetXY(70,0)
		endif

		player = new TPlayer
		camera = new TCamera
		camera.SetParent(tower)
		camera.target = player

		player.SetPosition(tower.Col2X(0.5), tower.Row2Y(0))
		player.area.SetWH(40, 20)


		for local i:int = 0 until 64
			starsX[i] = Rand(0, 320)
			starsY[i] = Rand(0, 200)
		Next
	End Method


	Method Reset:int()
	End Method


	Method Init()
	End Method


	Function Lerp:Float(v:float, addPerSecond:Float, dt:float)
		 return v + (addPerSecond * dt)
	End Function


	Function WrapValue:Float(v:Float, vMin:Float, vMav:Float)
		if v < vMin
			return vMav - (vMin - v) mod (vMav - vMin)
		else
			return vMin + (v - vMin) mod (vMav - vMin)
		endif
	End Function


	'transform tower-x-coord to screen coord
	Method X2ScreenX:Float(x:Float, radius:int=-1)
		x :- camera.GetX()
'		x = floor(x)

		if not tower.flatMode
			if radius = -1 then radius = tower.radiusInner
			return radius * sin((tower.WrapX(x) / float(tower.GetWidth()) * 180.0/Pi) * 2.0 * PI)
		else
			x = tower.WrapX(x)
			if (x > (tower.GetWidth()/2.0))
				x = -(tower.GetWidth() - x)
				'mirroring needs a odd number (1-2--3--2-1 vs 1--2-2--1)
				if tower.GetWidth() mod 2 = 0 then x :- 1
			endif
			'avoid border-flickering on the most left bricks
			if (x < -190) 'TODO: why 190?
				x :- 1
			endif
			return x
		endif
	End Method


	'transform tower-y-coord to screen coord
	Method Y2ScreenY:Float(y:Float)
		return tower.GetHeight() - GROUND_HEIGHT - (tower.GetY() - camera.area.GetY())
	End Method
	

	'transform local y to renderY
	Method TransformY:Float(y:Float)
		return APP_HEIGHT - GROUND_HEIGHT - tower.ROW_HEIGHT - (y - camera.area.GetY())
	End Method
	

	Method RenderMapTiles(colMin:int, colMax:int, direction:int)
		local rowMin:int = max(0, tower.Y2Row(camera.area.GetY() - GROUND_HEIGHT) - 1)
		local rowMax:int = min(tower.rows - 1, rowMin + (APP_HEIGHT / tower.ROW_HEIGHT + 1))
		local cell:int
		local col:int = colMin

		while col <> colMax
			for local row:int = rowMin to rowMax
				local y:int = TransformY(row * tower.ROW_HEIGHT)

				local tileType:int = tower.GetTile(col, row)
				if tileType = TTower.TILETYPE_PATH
					local x:int = col * tower.COL_WIDTH
					'attention: use _center_ of the tile
		'			local angle:int = WrapValue(tower.X2Angle(x + 0.5 * tower.PLATFORM_WIDTH, tower.radiusOuter) - tower.X2Angle(camera.area.GetX(), tower.radiusOuter), -180, 180)
					local angle:int = WrapValue(tower.X2Angle(x + 0.5 * tower.PLATFORM_WIDTH, tower.radiusOuter) - tower.X2Angle(camera.area.GetX(), tower.radiusOuter), -180, 180)
					'if tower.flatMode then angle = 0

					if tower.flatMode or MathHelper.inInclusiveRange(angle, 0, 180)
						'add col_width as the cols are centered too
						x = X2ScreenX(x, tower.radiusOuter) + tower.radiusOuter + 0.5*tower.PLATFORM_WIDTH -4 + 0.5
						rem
							local effWidth:int

							if angle = 90
								effWidth = 0
							elseif angle = 0
								effWidth = tower.COL_WIDTH
							else
								effWidth = floor(cos(abs(angle)) * tower.COL_WIDTH)
							endif
							DrawRect(x, y+15, effWidth, 15)
						endrem
						SetColor 0,0,0
						DrawRect(x + 1*tower.PLATFORM_WIDTH/2, y, tower.PLATFORM_WIDTH, 12)
						SetColor 0 + (col mod 2)*100,50,100
						DrawRect(x + 1*tower.PLATFORM_WIDTH/2 +1, y +1, tower.PLATFORM_WIDTH -2, 12-2)
						SetColor 255,255,255
						GetBitmapFont().Draw(angle, x + 1*tower.PLATFORM_WIDTH/2 +3, y +3)
					endif
				endif

rem
			
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
		wend

	End Method


	Method RenderBackground_Stars()
		local startX:int = WrapValue(APP_WIDTH  * camera.GetX()/float(tower.GetWidth()), 0, APP_WIDTH)
		local startY:int = WrapValue(APP_HEIGHT * camera.GetY()/float(tower.GetHeight()), 0, APP_HEIGHT)
		local negativeX:int = APP_WIDTH - startX 
		local negativeY:int = APP_HEIGHT - startY
		setColor 255,255,255
		For local i:int = 0 until 64
			'wrap around rotating axis
			local starX:int = WrapValue(startX + starsX[i], 0, APP_WIDTH)
			DrawRect(starX, startY + starsY[i], 1,1)
		Next
	End Method


	Method RenderBackground()
		RenderBackground_Stars()
	
		local l:Float = tower.X2Col(camera.area.GetX() - tower.GetWidth()/4.0)
		local r:Float = tower.X2Col(camera.area.GetX() + tower.GetWidth()/4.0)

'rendert nix
		'render parts of the map left and right of the tower
		SetColor 150,0,0
		RenderMapTiles(tower.WrapCol(l - 3), l, +1)
		SetColor 0,150,0
		RenderMapTiles(tower.WrapCol(r + 3), r, -1)
	End Method


	Method RenderForeground()
		local l:Float = tower.X2Col(camera.area.GetX() - tower.GetWidth()/4.0)
		local c:Float = tower.X2Col(camera.area.GetX())
		local r:Float = tower.X2Col(camera.area.GetX() + tower.GetWidth()/4.0)

		'render parts of the map left and right of the tower
		SetColor 250,0,0
		RenderMapTiles(l, tower.WrapCol(c    ), +1)
		SetColor 0,250,0
		RenderMapTiles(r, tower.WrapCol(c - 1), -1)


		'draw ground _after_ tower, so a "tower in destruction" can move
		'downwards without trouble
		SetColor 255,255,255
		local startOffset:int = camera.area.GetX()
		local groundSprite:TSprite = GetSpriteFromRegistry("ground")
		groundSprite.TileDrawHorizontal(-startOffset mod groundSprite.GetWidth(), APP_HEIGHT, APP_WIDTH + groundSprite.GetWidth(), ALIGN_LEFT_BOTTOM)
	End Method


	Method RenderDebug()
		local startX:int = WrapValue(APP_WIDTH  * camera.GetX()/float(tower.GetWidth()), 0, APP_WIDTH)
		local startY:int = WrapValue(APP_HEIGHT * camera.GetY()/float(tower.GetHeight()), 0, APP_HEIGHT)
		SetColor 255,0,0
		GetBitmapFont().DrawStyled("start: x="+startX+" y="+startY, 0,0, null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("camera: x="+int(camera.GetX())+" y="+int(camera.GetY())+"  rx="+int(camera.area.GetX()), 0,7, null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("tower: w="+int(tower.GetWidth())+" h="+int(tower.GetHeight())+" cols="+tower.cols+" rows="+tower.rows, 0,14, null, TBitmapFont.STYLE_SHADOW, 1, 2.0)
		GetBitmapFont().DrawStyled("player: x="+int(player.GetX())+" y="+int(player.GetY())+" rx="+int(player.area.GetX()), 0,21, null, TBitmapFont.STYLE_SHADOW, 1, 2.0)

		SetColor 255,255,255
	End Method
	

	Method Update:int()
		player.Update()

		camera.Update()
	End Method


	Method Render:Int()
		tower.render(x, y)

		'=== RENDER ===
		'adjust interpolation
		local dt:Float = GetDeltaTimer().GetTween()
		player.area.position.x = Tower.WrapX(player.GetX() + TInterpolation.Linear(0, player.velocity.GetX(),  dt, 1.0))
		player.area.position.y = player.GetY() + TInterpolation.Linear(0, player.velocity.GetY(),  dt, 1.0)
		camera.area.position.x = tower.WrapX(player.GetX() + TInterpolation.Linear(0, player.velocity.GetX(),  dt, 1.0))
		camera.area.position.y = camera.GetY() + TInterpolation.Linear(0, camera.velocity.GetY(),  dt, 1.0)

		'limit tweened position
		player.area.position.y = max(0, player.area.position.y)
		camera.area.position.y = max(0, camera.area.position.Y)

		RenderBackground()

		tower.Render()

		RenderForeground()

		RenderDebug()
	End Method
End Type



Type TTower extends TEntity

	Field tiles:Int[]
	Field cols:Int
	Field rows:Int
	Field radiusInner:int
	Field radiusOuter:int

	'show 3d or 2d tower?
	Global flatMode:int = false
	Global debugView:int = False

	Global COL_WIDTH:int = 32 '31 '27
	Global ROW_HEIGHT:int = 33 '27
	Global ROW_SURFACE:int = 12 '3
	Global PLATFORM_WIDTH:int = 0

	Const TILETYPE_GROUND:int = -1
	Const TILETYPE_AIR:int = 0
	Const TILETYPE_PATH:int = 1

	
	Method Init:TTower(cols:Int, rows:Int)
		Self.cols = cols
		Self.rows = rows
		tiles = New Int[cols * rows]
		area.SetWH(cols * COL_WIDTH, rows  * ROW_HEIGHT)

		SetFlatMode(False)

		local map:string
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
		
		
		return self
	End Method


	Method SetFlatMode(bool:int)
		flatMode = bool

		if not flatMode
			area.SetXY(70,0)
		else
			area.SetXY(0,0)
		endif

		
		'method 1) (define by radius)
		'COL_WIDTH = ceil(2*pi*radiusInner / cols)
		'method 2) (define by COL_WIDTH)
		radiusInner = (cols * COL_WIDTH) / (2*pi) + 0.5

		'radius = GetWidth() / 4
		'radiusInner = APP_WIDTH / 4
		if flatMode then radiusInner = radiusInner * 2
		

		radiusOuter = radiusInner * 1.2

		'this.platformWidth = FLAT ? COL_WIDTH : 2 * tower.or * Math.tan((360/tower.cols) * Math.PI / 360);
		if flatMode
			PLATFORM_WIDTH = COL_WIDTH
		else
			PLATFORM_WIDTH = 2 * radiusOuter * tan((360.0/cols * 180.0/PI) * PI/360.0)
		endif
	End Method


	Method InitTilesFromString:int(s:string, mapWidth:int = -1)
		local lines:string[] = s.split("~n")
		local index:int = 0
		local lineIndex:int = 0

		if mapWidth = -1 then mapWidth = lines[0].length

		'process from bottom to top
		for local lineNumber:int = lines.length-1 to 0 step -1
			local line:string = lines[lineNumber]
			lineIndex = 0
			for local i:int = 0 until line.length
				local tileType:int = 0
				if line[i] = asc("x") then tileType = 1

				tiles[index + lineIndex] = tileType
				lineIndex :+ 1
			next
			index :+ mapWidth
		next
	End Method


	'=== HELPER ===

	'wrap x coord within tower limits
	Method WrapX:Float(x:Float)
		return TLevel.WrapValue(x, 0, area.GetW())
	End Method


	'wrap column  around to stay within tower boundary
	Method WrapCol:Float(col:Float)
		return TLevel.WrapValue(col, 0, cols)
	End Method


	'convert x coord to column number
	Method X2Col:int(x:Float)
		return int(WrapX(x) / COL_WIDTH)
	End Method


	'convert y coord to row number
	Method Y2Row:int(y:Float)
		return int(y / ROW_HEIGHT)
	End Method


	'convert column to coord
	Method Col2X:Float(col:Float)
		return col * COL_WIDTH
	End Method


	'convert row to coord
	Method Row2Y:Float(row:Float)
		return row * ROW_HEIGHT
	End Method


	'convert x coord to angle (360 = one time around the tower)
	Method X2Angle:Float(x:Float, radius:int = -1)
		if radius = -1 then radius = area.GetW()/2
		return 360.0 * (WrapX(x) / (2*radius))
	End Method


	'returns whether an x coord is near a column's center
	Method IsNearColumnCenter:int(x:Float, column:int, limit:int)
		return limit > abs(x - Col2X(column + 0.5)) / ( COL_WIDTH / 2.0)
	End Method


	'returns whether a y coord is near the surface of a row
	Method IsNearRowSurface:int(y:float, row:int)
		return y > (Row2Y(row + 1) - ROW_SURFACE)
	End Method


	Method GetTile:int(col:int, row:int)
		if row < 0
			return TILETYPE_GROUND
		elseif row >= rows
			return 0;
			return TILETYPE_AIR
		else
			return tiles[row * cols + col ]
		endif
	End Method


	Method RenderBricks:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		'offset tiles/bricks every odd/even row
'		local offsets:Float[] = [0.0, 0.30, 0.6, 1.2]
		local offsets:Float[] = [0.0]
		local offset:int = 0

		for local row:int = 0 until rows
			local rowY:int = level.TransformY( row * ROW_HEIGHT)
			'visible?
			if MathHelper.inInclusiveRange(rowY, -ROW_HEIGHT, APP_HEIGHT - level.GROUND_HEIGHT)
				RenderBrickRow(rowY, offsets[offset], xOffset, yOffset)
			endif
			offset = (offset + 1) mod offsets.length
		Next
	End Method


	Method RenderBrickRow(y:float, offset:Float, xOffset:Float = 0, yOffset:Float = 0)
		RenderBrickRow_JITTERING(y, offset, xOffset, yOffset)
		'RenderBrickRow_JITTERCORRECTED(y, offset, xOffset, yOffset)
	End Method


	Method RenderBrickRow_JITTERING(y:float, offset:Float, xOffset:Float = 0, yOffset:Float = 0)
		for local col:int = 0 until cols
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

			GetSpriteFromRegistry("wall."+((col mod 3) +1)).DrawResized(new TRectangle.Init(GetScreenX() + x, y, effWidth, ROW_HEIGHT))
			'DrawOval(GetScreenX() + x-5, 130, 10, 10)
		next
	End Method

	
	Method RenderBrickRow_JITTERCORRECTED(y:float, offset:Float, xOffset:Float = 0, yOffset:Float = 0)
		local x:int
		local angle:Float
		local effWidth:int

		local mostLeft:int = 0
		local mostLeftX:int = 10000
		local visible:int[] = new Int[cols]
		local widths:int[] = new Int[cols]
		local startXs:int[] = new Int[cols]
		local mostCenter:int = 0
		local mostCenterDistance:int = 10000

		for local col:int = 0 until cols
			x = (col + offset) * COL_WIDTH
			'attention: use _center_ of the tile
			angle = level.WrapValue(X2Angle(x + 0.5 * COL_WIDTH) - X2Angle(level.camera.area.GetX()), -180, 180)
			if flatMode then angle = 0

			if flatMode or MathHelper.inInclusiveRange(angle, -95, 95)
				visible[col] = true
			endif

			x = level.X2ScreenX(x) + radiusInner + 0.5

'if y=114 then print "col"+col+"  x=" + x +"   angle:" + level.WrapValue(int(angle), 0, TOWER_ANGLES-1)
			if angle = 90
				effWidth = 0
			elseif angle = 0
				effWidth = COL_WIDTH
			else
				effWidth = floor(cos(abs(angle)) * COL_WIDTH)
			endif

			if effWidth <= 0
				visible[col] = false
				continue
			endif


			widths[col] = effWidth
			startXs[col] = x


			if mostLeftX > x
				mostLeft = col
				mostLeftX = x
			endif
		
			if mostCenterDistance > abs(x + 0.5 * COL_WIDTH - radiusInner)
				mostCenter = col
				mostCenterDistance = abs(x + 0.5 * COL_WIDTH - radiusInner)
			endif
		Next


		'check for too big gaps
'rem
		local totalWidth:int = 2*radiusInner
		local reachedWidth:int = 0
		For local col:int = mostLeft until cols + mostLeft
			local colIndex:int = col mod cols
			if not visible[colIndex] then continue
			reachedWidth :+ widths[colIndex]
		Next

		'start the most left when in rotating-tower-mode
		if not flatMode then startXs[mostLeft] = 0

		local addWidth:int = max(0,(totalWidth - reachedWidth))
		local widthAccumulator:Float = 0.0
		for local col:int = mostLeft until cols + mostLeft
			local colIndex:int = col mod cols
			if not visible[colIndex] then continue

			local nextColIndex:int = (colIndex +1) mod cols
			'nothing adjustable coming
			if not visible[nextColIndex] then continue

			'increase width
			widthAccumulator :+ widths[colIndex] / float(totalWidth) * addWidth
			if widthAccumulator >= 1.0
				widths[colIndex] :+ 1
				widthAccumulator :- 1
			endif


			startXs[nextColIndex] = startXs[colIndex] + widths[colIndex]

			'limit width
'			if startXs[nextColIndex] + widths[nextColIndex] > radiusInner
'				widths[nextColIndex] = 2*radiusInner - startXs[nextColIndex]
'			endif
		next
'endrem

		local lastX2:int
		for local col:int = 0 until cols
			if not visible[col] then continue
			
			if debugView 'or 1 = 1
'				SetColor 0,0,0
				SetColor 0,(col mod 2)*150,(1-(col mod 2))*150
				DrawRect(GetScreenX() + startXs[col], y, widths[col], ROW_HEIGHT)
				SetColor 255,150,0
				DrawRect(GetScreenX() + startXs[col]+1, y+1, Max(1,widths[col]-2), ROW_HEIGHT-2)
				SetColor 0,0,0
				GetBitmapFont().Draw("X"+x, GetScreenX() + startXs[col], y+3)
				SetColor 255,255,255
			else
				'GetSpriteFromRegistry("wall."+(col mod 3 +1)).Draw(GetScreenX() + startXs[col], y)
				GetSpriteFromRegistry("wall."+((col mod 3) +1)).DrawResized(new TRectangle.Init(GetScreenX() + startXs[col], y, widths[col], ROW_HEIGHT))
rem
				'drawimage
				SetColor 50 + (col mod 2)*200,(1 - col mod 2)*200,0
				DrawRect(GetScreenX() + startXs[col], y, Max(1,widths[col]), ROW_HEIGHT*0.5)

				SetColor 255,150,0
				DrawRect(GetScreenX() + startXs[col]+1, y+1, Max(1,widths[col]-2), ROW_HEIGHT-2)
				SetColor 255,255,255
endrem
			endif
		next
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		local top:int = Max(0, level.TransformY(GetHeight()))
		local bottom:int = Min(APP_HEIGHT, level.TransformY(0) + level.tower.ROW_HEIGHT)

		if not flatMode
			local vpX:int, vpY:int, vpH:int, vpW:int
			GetViewport(vpX, vpY, vpH, vpW)

			SetViewport(GetScreenX(), top, radiusInner*2, bottom-top)

			'render background
			SetColor 0,0,0
			DrawRect(GetScreenX(), top, radiusInner*2, bottom - top)
			SetColor 255,255,255

			RenderBricks(xOffset, yOffset, alignment)

			SetViewport(vpX, vpY, vpW, vpH)
		else
			RenderBricks(xOffset, yOffset, alignment)
		endif


		for local x:int = 0 to 546 step 32
			local angle:int = level.WrapValue(X2Angle(x) - X2Angle(level.camera.area.GetX()), -180, 180)
			local screenX:int = level.X2ScreenX(x) + radiusInner + 0.5
			if not flatMode and not MathHelper.inInclusiveRange(angle, -90, 90)
				SetBlend Alphablend
				SetAlpha 0.25
			endif
			SetColor 255 - (x / 32) * 25, 0,255
			DrawOval(GetScreenX() + screenX-5, 100, 10, 10)
			SetBlend MaskBlend
			SetAlpha 1.0
			if x = 0
				GetBitmapFont().Draw("x="+screenX, 5, 84)
				GetBitmapFont().Draw("a="+angle, 5, 92)
			endif
			if x = 32
				GetBitmapFont().Draw("x="+screenX, 40, 84)
				GetBitmapFont().Draw("a="+angle, 40, 92)
			endif
		next

		'outer ring
		for local x:int = 0 to 546 step 32
			local angle:int = level.WrapValue(X2Angle(x) - X2Angle(level.camera.area.GetX()), -180, 180)
			local screenX:int = level.X2ScreenX(x, radiusOuter) + radiusInner + 0.5
			if not flatMode and not MathHelper.inInclusiveRange(angle, -90, 90)
				SetBlend Alphablend
				SetAlpha 0.25
			endif
			SetColor 255 - (x / 32) * 25, 0,255
			DrawOval(GetScreenX() + screenX-5, 120, 10, 10)
			SetBlend MaskBlend
			SetAlpha 1.0
			if x = 0
				GetBitmapFont().Draw("x="+screenX, 5, 84 + 50)
				GetBitmapFont().Draw("a="+angle, 5, 92 + 50)
			endif
			if x = 32
				GetBitmapFont().Draw("x="+screenX, 40, 84 + 50 )
				GetBitmapFont().Draw("a="+angle, 40, 92 + 50)
			endif
		next

rem
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




Type TPlayer extends TEntity
	Field automove:int = True

	Method Update:int()
		local dx:Float = 0
		local dy:Float = 0

		automove = False
		if KeyDown(KEY_LALT) then automove = true

		if automove
			dx = -60
		else
			If KeyDown(key_left) Then
				dx = -40
			End If
			
			If KeyDown(key_right) Then
				dx = +40
			End If
		endif

		if Keyhit(KEY_SPACE) then area.position.x :- 1

'		If KeyHit(key_left) Then area.position.x :-1
'		If KeyHit(key_right) Then area.position.x :+1

		area.position.x = level.tower.WrapX(area.position.x + GetDeltaTime() * dx)
		area.position.y :+ GetDeltaTime() * dy
		'todo: jump/fall
	End Method
End Type




Type TCamera extends TEntity
	Field target:TEntity
	Field positionLimit:TRectangle
	

	Method New()
		Reset()
	End Method


	Method Reset:Int()
		if target
			SetPosition(target.area.GetX(), target.area.GetY())
		endif
		SetVelocity(0,0)

		'constrain position
		if parent
			positionLimit = new TRectangle.Init(-1, 0, -1, parent.GetHeight())
		endif
	End Method


	Method Update:Int()
		Super.Update()

		'move to target
		if target
			SetPosition(target.area.position.x, target.area.position.y)
			SetVelocity(target.velocity.x, target.velocity.y)
		endif
	End Method
End Type