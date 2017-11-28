SuperStrict
'to access sprites and their information (eg. width/height)
Import "game.assets.bmx"
Import "game.gamelevel.bmx"



Type TGameLevel_Tower extends TGameLevel

	Method Update:int()
		If not Super.Update() then return False
	End Method


	Method Render:int()
		'=== DEMO GRAPHICS ===
		local groundSprite:TSprite = GetSpriteFromRegistry("ground")
		local wallSprites:TSprite[] = new TSprite[4]
		for local i:int = 0 until 4
			wallSprites[i] = GetSpriteFromRegistry("wall."+(i+1))
		next
		local elfSprite:TSprite = GetSpriteFromRegistry("elf.idle")
		local santaSprite:TSprite = GetSpriteFromRegistry("santa.idle")
		local path1Sprite:TSprite = GetSpriteFromRegistry("path.1")
		local path2Sprite:TSprite = GetSpriteFromRegistry("path.2")
		local path3Sprite:TSprite = GetSpriteFromRegistry("path.3")
		local pathShadow1Sprite:TSprite = GetSpriteFromRegistry("path.shadow.1")
		local pathShadow2Sprite:TSprite = GetSpriteFromRegistry("path.shadow.2")
		local pathShadow3Sprite:TSprite = GetSpriteFromRegistry("path.shadow.3")
		local pathShadowTop1Sprite:TSprite = GetSpriteFromRegistry("path.shadow.top.1")

		local screenCenterX:int = 0.5 * GetGraphicsManager().GetWidth()
		local towerStartX:int = screenCenterX - 3 * wallSprites[0].GetWidth()
		local pathHeight:int = 12
		local pathStepHeight:int = pathHeight - 3 '-3 = top of the step platform


		'hidden from tower-paths
		path1Sprite.Draw(towerStartX - path1Sprite.GetWidth(), 100 )

		path1Sprite.Draw(towerStartX + 3.5*path1Sprite.GetWidth(), 100 + 4*pathStepHeight )
		path1Sprite.Draw(towerStartX + 3.5*path1Sprite.GetWidth(), 100 + 3*pathStepHeight )
		pathShadow3Sprite.Draw(towerStartX + 3.5*path1Sprite.GetWidth(), 100 + 3*pathStepHeight + pathHeight)

		'the tower
		local wallY:int = GetGraphicsManager().GetHeight() - groundSprite.GetHeight() - wallSprites[0].GetHeight()
		For local y:int = 0 to 10
			local wallX:int = towerStartX
			For local x:int = 0 to 5
				wallSprites[(x+y) mod 4].Draw(wallX, wallY)
				wallX :+ wallSprites[0].GetWidth()
			Next
			wallY :- wallSprites[0].GetHeight()
		Next

		'paths in front of the tower
		path2Sprite.Draw(towerStartX + 0*path1Sprite.GetWidth(), 100 + 1*pathStepHeight )
		pathShadow2Sprite.Draw(towerStartX + 0*path1Sprite.GetWidth(), 100 + 1*pathStepHeight + pathHeight)

		path3Sprite.Draw(towerStartX + 1*path1Sprite.GetWidth(), 100 + 1*pathStepHeight )
		'pathShadowTop1Sprite.Draw(towerStartX + 1*path1Sprite.GetWidth(), 100 + 1*pathStepHeight -1)
		pathShadow2Sprite.Draw(towerStartX + 1*path1Sprite.GetWidth(), 100 + 1*pathStepHeight + pathHeight)

		path1Sprite.Draw(towerStartX + 2*path1Sprite.GetWidth(), 100 + 2*pathStepHeight )
		pathShadow2Sprite.Draw(towerStartX + 2*path1Sprite.GetWidth(), 100 + 2*pathStepHeight + pathHeight)
		path1Sprite.Draw(towerStartX + 3*path1Sprite.GetWidth(), 100 + 2*pathStepHeight )
		pathShadow2Sprite.Draw(towerStartX + 3*path1Sprite.GetWidth(), 100 + 2*pathStepHeight + pathHeight)


		'sample entity
		elfSprite.Draw(towerStartX + 1 * wallSprites[0].GetWidth(), 100 + 1*pathStepHeight +2, -1, ALIGN_LEFT_BOTTOM) 'feets at y

		'draw ground _after_ tower, so a "tower in destruction" can move
		'downwards without trouble
		groundSprite.TileDrawHorizontal(0, GetGraphicsManager().GetHeight(), GetGraphicsManager().GetWidth(), ALIGN_LEFT_BOTTOM)

		'player: it is drawn before the ground - as he might be able to
		'walk on it
		santaSprite.Draw(towerStartX + 2 * wallSprites[0].GetWidth(), 100 + 1*pathStepHeight +2, -1, ALIGN_LEFT_BOTTOM) 'feets at y

		'draw tower
		'draw enemies
		'draw player
	End Method
End Type