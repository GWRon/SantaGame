SuperStrict
Import "game.gameentity.bmx"



Type TGameBase
	Global _instance:TGameBase


	Function GetInstance:TGameBase()
		If Not _instance Then _instance = New TGameBase.Initialize()
		Return _instance
	End Function


	Method Initialize:TGameBase()
		Return Self
	End Method


	Method Render()
	End Method


	Method Update()
	End Method


	Method IsGameOver:int()
		return False
	End Method


	Method onFinishLevel:int()
	End Method


	Method onStartLevel:int()
	End Method


	Method onKillEnemy:Int(entity:TGameEntity)
	End Method
End Type

'=== CONVENIENCE ACCESSOR ===
Function GetGameBase:TGameBase()
	Return TGameBase.GetInstance()
End Function