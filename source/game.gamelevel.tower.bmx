SuperStrict
'to access sprites and their information (eg. width/height)
Import "game.assets.bmx"
Import "game.gamelevel.bmx"



Type TGameLevel_Tower extends TGameLevel

	Method Update:int()
		If not Super.Update() then return False
	End Method


	Method Render:int()
		'=== demo graphics ==
		local groundSprite:TSprite = GetSpriteFromRegistry("ground")
		local wallSprite:TSprite = GetSpriteFromRegistry("wall.frozen")
		local pathSprite:TSprite = GetSpriteFromRegistry("path.frozen")
		local path2Sprite:TSprite = GetSpriteFromRegistry("path.halffrozen")


		'hidden from tower-paths
		pathSprite.Draw(0.5 * GetGraphicsManager().GetWidth() - 3 * wallSprite.GetWidth() - pathSprite.GetWidth(), 100 )
		pathSprite.Draw(0.5 * GetGraphicsManager().GetWidth() - 3 * wallSprite.GetWidth() + 4*pathSprite.GetWidth(), 100 + 4*9 )

		'the tower
		local wallY:int = GetGraphicsManager().GetHeight() - groundSprite.GetHeight() - wallSprite.GetHeight()
		For local y:int = 0 to 10
			local wallX:int = 0.5 * GetGraphicsManager().GetWidth() - 3 * wallSprite.GetWidth()
			For local x:int = 0 to 5
				wallSprite.Draw(wallX, wallY)
				wallX :+ wallSprite.GetWidth()
			Next
			wallY :- wallSprite.GetHeight()
		Next

		'paths in front of the tower
		path2Sprite.Draw(0.5 * GetGraphicsManager().GetWidth() - 3 * wallSprite.GetWidth() + 0*pathSprite.GetWidth(), 100 + 1*9 )
		path2Sprite.Draw(0.5 * GetGraphicsManager().GetWidth() - 3 * wallSprite.GetWidth() + 1*pathSprite.GetWidth(), 100 + 1*9 )
		pathSprite.Draw(0.5 * GetGraphicsManager().GetWidth() - 3 * wallSprite.GetWidth() + 2*pathSprite.GetWidth(), 100 + 2*9 )
		pathSprite.Draw(0.5 * GetGraphicsManager().GetWidth() - 3 * wallSprite.GetWidth() + 3*pathSprite.GetWidth(), 100 + 2*9 )
		pathSprite.Draw(0.5 * GetGraphicsManager().GetWidth() - 3 * wallSprite.GetWidth() + 4*pathSprite.GetWidth(), 100 + 3*9 )

		'draw ground _after_ tower, so a "tower in destruction" can move
		'downwards without trouble
		groundSprite.TileDrawHorizontal(0, GetGraphicsManager().GetHeight(), GetGraphicsManager().GetWidth(), ALIGN_LEFT_BOTTOM)

		'draw tower
		'draw enemies
		'draw player
	End Method
End Type