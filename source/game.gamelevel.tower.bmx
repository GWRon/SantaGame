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
		local wallSprite:TSprite = GetSpriteFromRegistry("wall.frozen")
		local elfSprite:TSprite = GetSpriteFromRegistry("elf.idle")
		local santaSprite:TSprite = GetSpriteFromRegistry("santa.idle")
		local pathSprite:TSprite = GetSpriteFromRegistry("path.frozen")
		local path2Sprite:TSprite = GetSpriteFromRegistry("path.halffrozen")
		local pathShadowSprite:TSprite = GetSpriteFromRegistry("path.shadow")

		local screenCenterX:int = 0.5 * GetGraphicsManager().GetWidth()
		local towerStartX:int = screenCenterX - 3 * wallSprite.GetWidth()


		'hidden from tower-paths
		pathSprite.Draw(towerStartX - pathSprite.GetWidth(), 100 )
		pathSprite.Draw(towerStartX + 4*pathSprite.GetWidth(), 100 + 4*9 )

		'the tower
		local wallY:int = GetGraphicsManager().GetHeight() - groundSprite.GetHeight() - wallSprite.GetHeight()
		For local y:int = 0 to 10
			local wallX:int = towerStartX
			For local x:int = 0 to 5
				wallSprite.Draw(wallX, wallY)
				wallX :+ wallSprite.GetWidth()
			Next
			wallY :- wallSprite.GetHeight()
		Next

		'paths in front of the tower
		path2Sprite.Draw(towerStartX + 0*pathSprite.GetWidth(), 100 + 1*9 )
		pathShadowSprite.Draw(towerStartX + 0*pathSprite.GetWidth(), 100 + 1*9 + 9)

		path2Sprite.Draw(towerStartX + 1*pathSprite.GetWidth(), 100 + 1*9 )
		pathShadowSprite.Draw(towerStartX + 1*pathSprite.GetWidth(), 100 + 1*9 + 9)

		pathSprite.Draw(towerStartX + 2*pathSprite.GetWidth(), 100 + 2*9 )
		pathSprite.Draw(towerStartX + 3*pathSprite.GetWidth(), 100 + 2*9 )
		pathSprite.Draw(towerStartX + 4*pathSprite.GetWidth(), 100 + 3*9 )

		'sample entity
		elfSprite.Draw(towerStartX + 1 * wallSprite.GetWidth(), 100 + 1*9, -1, ALIGN_LEFT_BOTTOM) 'feets at y

		'draw ground _after_ tower, so a "tower in destruction" can move
		'downwards without trouble
		groundSprite.TileDrawHorizontal(0, GetGraphicsManager().GetHeight(), GetGraphicsManager().GetWidth(), ALIGN_LEFT_BOTTOM)

		'player: it is drawn before the ground - as he might be able to
		'walk on it
		santaSprite.Draw(towerStartX + 2 * wallSprite.GetWidth(), 100 + 1*9, -1, ALIGN_LEFT_BOTTOM) 'feets at y

		'draw tower
		'draw enemies
		'draw player
	End Method
End Type