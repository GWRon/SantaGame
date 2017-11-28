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
	Global GROUND_HEIGHT:int = 20


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
	Method X2ScreenX:Float(x:Float)
		x :- camera.GetX()
'		x = floor(x)

		return tower.X2ScreenX(x)
	End Method


	'transform tower-y-coord to screen coord
	Method Y2ScreenY:Float(y:Float)
		return tower.GetHeight() - GROUND_HEIGHT - (tower.GetY() - camera.area.GetY())
	End Method
	

	'transform local y to renderY
	Method TransformY:Float(y:Float)
		return APP_HEIGHT - GROUND_HEIGHT - (y - camera.area.GetY())
	End Method
	

	Method RenderMapTiles(colMin:int, colMax:int, direction:int)
		local rowMin:int = max(0, tower.Y2Row(camera.area.GetY() - GROUND_HEIGHT) - 1)
		local rowMax:int = min(tower.rows - 1, rowMin + (APP_HEIGHT / tower.ROW_HEIGHT + 1))
		local cell:int
		local col:int = colMin

		while col <> colMax
			for local row:int = rowMin to rowMax
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
	End Method


	Method RenderDebug()
		local startX:int = WrapValue(APP_WIDTH  * camera.GetX()/float(tower.GetWidth()), 0, APP_WIDTH)
		local startY:int = WrapValue(APP_HEIGHT * camera.GetY()/float(tower.GetHeight()), 0, APP_HEIGHT)
		SetColor 255,0,0
		GetBitmapFont().Draw("start: x="+startX+" y="+startY, 0,0)
		GetBitmapFont().Draw("camera: x="+int(camera.GetX())+" y="+int(camera.GetY())+"  rx="+int(camera.area.GetX()), 0,10)
		GetBitmapFont().Draw("tower: w="+int(tower.GetWidth())+" h="+int(tower.GetHeight())+" cols="+tower.cols+" rows="+tower.rows, 0,20)
		GetBitmapFont().Draw("player: x="+int(player.GetX())+" y="+int(player.GetY())+" rx="+int(player.area.GetX()), 0,40)

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

	Field blocks:Int[]
	Field cols:Int
	Field rows:Int
	Field radiusInner:int
	Field radiusOuter:int

	'show 3d or 2d tower?
	Global flatMode:int = false
	Global debugView:int = False

	Global COL_WIDTH:int = 31 '27
	Global ROW_HEIGHT:int = 33 '27
	Global ROW_SURFACE:int = 12 '3

	
	Method Init:TTower(cols:Int, rows:Int)
		Self.cols = cols
		Self.rows = rows
		blocks = New Int[cols * rows]
		area.SetWH(cols * COL_WIDTH, rows  * ROW_HEIGHT)

		'method 1) (define by radius)
		'COL_WIDTH = ceil(2*pi*radiusInner / cols)
		'method 2) (define by COL_WIDTH)
		radiusInner = (cols * COL_WIDTH) / (2*pi)'+ 0.5

		'radius = GetWidth() / 4
		'radiusInner = APP_WIDTH / 4
		if flatMode then radiusInner = radiusInner * 2
		

		radiusOuter = radiusInner * 1.2

		'this.platformWidth = FLAT ? COL_WIDTH : 2 * tower.or * Math.tan((360/tower.cols) * Math.PI / 360);
		
		return self
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


	Method X2ScreenX:int(x:float)
		if not flatMode
			return radiusInner * sin((WrapX(x) / float(GetWidth()) * 180.0/Pi) * 2.0 * PI)
		else
			x = WrapX(x)
			if (x > (GetWidth()/2.0))
				x = -(GetWidth() - x)
				'mirroring needs a odd number (1-2--3--2-1 vs 1--2-2--1)
				if GetWidth() mod 2 = 0 then x :- 1
			endif
			'avoid border-flickering on the most left bricks
			if (x < -190) 'TODO: why 190?
				x :- 1
			endif
			return x
		endif
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
	Method X2Angle:Float(x:Float)
		return 360.0 * (WrapX(x) / area.GetW())
	End Method


	'returns whether an x coord is near a column's center
	Method IsNearColumnCenter:int(x:Float, column:int, limit:int)
		return limit > abs(x - Col2X(column + 0.5)) / ( COL_WIDTH / 2.0)
	End Method


	'returns whether a y coord is near the surface of a row
	Method IsNearRowSurface:int(y:float, row:int)
		return y > (Row2Y(row + 1) - ROW_SURFACE)
	End Method



	Method RenderBricks:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		'offset tiles/bricks every odd/even row
		local offsets:Float[] = [0.0, 0.5]
		local offset:int = 0
	
		for local row:int = 0 until rows
			local rowY:int = level.TransformY( row * ROW_HEIGHT)
			'visible?
			if MathHelper.inInclusiveRange(rowY, -ROW_HEIGHT, APP_HEIGHT + ROW_HEIGHT)
				RenderBrickRow(rowY, offsets[offset], xOffset, yOffset)
			endif
			offset = (offset + 1) mod offsets.length
		Next
	End Method


	Method RenderBrickRow(y:float, offset:Float, xOffset:Float = 0, yOffset:Float = 0)
		local x:int
		local angle:Float
		local effWidth:int

rem
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
			if angle = 90
				effWidth = 0
			elseif angle = 0
				effWidth = COL_WIDTH
			else
				effWidth = floor(cos(abs(angle)) * COL_WIDTH)
			endif

			if effWidth < 0
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

if 1=2
			SetColor 0,0,0
			DrawRect(GetScreenX() + x, y, Max(1,widths[col]), ROW_HEIGHT - col)
			SetColor 100 + (col mod 2)*50,col*10,col*10
			DrawRect(GetScreenX() + x+1, y+1, Max(1,widths[col]-2), ROW_HEIGHT-2 - col)
			SetColor 0,0,0
			if visible[col]
				GetBitmapFont().Draw("Y", GetScreenX() + x+1, y+1)
			else
				GetBitmapFont().Draw("N", GetScreenX() + x+1, y+1)
			endif
endif
		next


		local leftX2:int = startXs[mostCenter] - 1
		local rightX:int = startXs[mostCenter] + widths[mostCenter] + 1
		For local i:int = 1 to 5
			local col:int

			for local even:int = 0 to 1
				col = (mostCenter - i + 2*even*i) mod widths.length
				if not visible[col] then continue

				local x:int
				if not even
					x = leftX2 - widths[col]
					leftX2 = x - 1
				else
					x = rightX
					rightX = x + 1
				endif

				SetColor 0,0,0
				DrawRect(GetScreenX() + x, y, widths[col], ROW_HEIGHT)
				SetColor 100 + (col mod 2)*50,col*10,col*10
				DrawRect(GetScreenX() + x+1, y+1, widths[col]-2, ROW_HEIGHT-2)
			Next
		Next
		
		SetColor 0,0,0
		DrawRect(GetScreenX() + startXs[mostCenter], y, Max(1,widths[mostCenter]), ROW_HEIGHT)
		SetColor 100 + (mostCenter mod 2)*50,mostCenter*10,mostCenter*10
		DrawRect(GetScreenX() + startXs[mostCenter]+1, y+1, Max(1,widths[mostCenter]-2), ROW_HEIGHT-2)
endrem

rem
		local leftTileX:int = 0
		local tileWidth:int = 0
		local rightTileX:int = 0
		For local i:int = 1 to 7
			local col:int

			'left
			col = (mostCenter - i) mod widths.length
			if widths[col] <= 0 then continue
'			if not visible[col] then continue

			leftTileX = GetScreenX() + startXs[col]
			tileWidth = Max(1, widths[col])
			
				
			SetColor 0,0,0
			DrawRect(leftTileX, y, tileWidth, ROW_HEIGHT)
'			if tileWidth > 2
				SetColor 100 + (col mod 2)*50,col*10,col*10
				DrawRect(leftTileX+1, y+1, tileWidth, ROW_HEIGHT-2)

'			endif


			'right
			col = (mostCenter + i) mod widths.length
			if widths[col] <= 0 then continue
'			if not visible[col] then continue

			rightTileX = GetScreenX() + startXs[col]
			tileWidth = Max(1, widths[col])
			
				
			SetColor 0,0,0
			DrawRect(rightTileX, y, tileWidth, ROW_HEIGHT)
'			if tileWidth > 2
				SetColor 100 + (col mod 2)*50,col*10,col*10
				DrawRect(rightTileX+1, y+1, tileWidth, ROW_HEIGHT-2)
'			endif
		Next

		SetColor 0,0,0
		DrawRect(GetScreenX() + startXs[mostCenter], y, Max(1,widths[mostCenter]), ROW_HEIGHT)
		SetColor 100 + (mostCenter mod 2)*50,mostCenter*10,mostCenter*10
		DrawRect(GetScreenX() + startXs[mostCenter]+1, y+1, Max(1,widths[mostCenter]-2), ROW_HEIGHT-2)
endrem

rem
		For local colBase:int = mostCenter until widths.length + mostCenter
			local col:int = colBase mod widths.length
			if widths[col] <= 0 then continue
			
			SetColor 0,0,0
			DrawRect(GetScreenX() + startXs[col], y, Max(1,widths[col]), ROW_HEIGHT)
			SetColor 100 + (col mod 2)*50,col*10,col*10
			DrawRect(GetScreenX() + startXs[col]+1, y+1, Max(1,widths[col]-2), ROW_HEIGHT-2)
'			if y = 114 then print col+" " + widths[col]
		Next
endrem


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
rem
		local totalWidth:int = 2*radiusInner
		for local col:int = mostLeft until cols + mostLeft
			local colIndex:int = col mod cols
			if not visible[colIndex] then continue

			local nextColIndex:int = (colIndex +1) mod cols
			'nothing adjustable coming
			if not visible[nextColIndex] then continue

			startXs[nextColIndex] = startXs[colIndex] + widths[colIndex] 
		next
endrem

		local lastX2:int
		for local col:int = 0 until cols
			if not visible[col] then continue
			
			if debugView
				SetColor 0,0,0
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


	Method RenderBrickRowOLD(y:float, offset:Float, xOffset:Float = 0, yOffset:Float = 0)
		local x:int
		local angle:int

		local lastX2:int
		for local col:int = 0 until cols 
			x = int( (col + offset) * COL_WIDTH)
			'attention: use _center_ of the tile
			angle = level.WrapValue(X2Angle(x + 0.5 * COL_WIDTH) - X2Angle(level.camera.area.GetX()), -180, 180)
			if flatMode then angle = 0

			'visible?
			if flatMode or MathHelper.inInclusiveRange(angle, -95, 95)
				'draw with items higher angle but limit to 90
				'avoids "jiggling"
				if angle < -90
					angle = Max(-95, angle )
				elseif angle > 90
					angle = Min(95, angle )
				endif
				x = level.X2ScreenX(x) + radiusInner + 0.5

				local effWidth:int = COL_WIDTH
				if not flatMode
					if angle = 90
						effWidth = 0
					elseif angle = 0
						effWidth = COL_WIDTH
					else
						effWidth = floor(cos(abs(angle)) * COL_WIDTH)
					endif

					'avoid gaps and increase tiles instead
					local distance:int = lastX2 - x
					if abs(distance) > 0 and abs(distance) < 3
						effWidth = Min(COL_WIDTH, effWidth - distance)
						x = lastX2
					endif
					if abs(distance) < -100
						effWidth :+ 10
					endif
				endif

				if debugView
					SetColor 0,0,0
					DrawRect(GetScreenX() + x, y, effWidth, ROW_HEIGHT)
					SetColor 255,150,0
					DrawRect(GetScreenX() + x+1, y+1, Max(1,effWidth-2), ROW_HEIGHT-2)
					SetColor 0,0,0
					GetBitmapFont().Draw("X"+x, GetScreenX() + x, y+3)
					SetColor 255,255,255
				else
					'drawimage
					SetColor 255,150,0
					DrawRect(GetScreenX() + x+1, y+1, Max(1,effWidth-2), ROW_HEIGHT-2)
if y=114
	SetColor 0,0,0
	GetBitmapFont().Draw(effWidth, GetScreenX() + x+1, y+3)
	GetBitmapFont().Draw(x, GetScreenX() + x+1, y+3 +12)
	SetColor 255,255,255
	GetBitmapFont().Draw(effWidth, GetScreenX() + x, y+2)
endif
					SetColor 255,255,255
				endif
			endif
		next
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		local top:int = Max(0, level.TransformY(GetHeight()))
		local bottom:int = Min(APP_HEIGHT, level.TransformY(0))

		local vpX:int, vpY:int, vpH:int, vpW:int
		GetViewport(vpX, vpY, vpH, vpW)

		SetViewport(GetScreenX(), top, radiusInner*2, bottom-top)

		'render background
		SetColor 0,0,0
		DrawRect(GetScreenX() + 1, top, radiusInner*2 - 2, bottom - top)
		SetColor 255,255,255

		RenderBricks(xOffset, yOffset, alignment)

		SetViewport(vpX, vpY, vpW, vpH)
    End Method
End Type




Type TPlayer extends TEntity

	Method Update:int()
		local dx:Float = 0
		local dy:Float = 0
		If KeyDown(key_left) Then
			dx = -40
		End If
		
		If KeyDown(key_right) Then
			dx = +40
		End If

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