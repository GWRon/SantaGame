SuperStrict
Framework Brl.StandardIO
Import "source/game.app.bmx"


local version:string = "v0.0nothing"

global app:TMyApp = new TMyApp
app.SetTitle("Santa Tower " + version)
app.Run()

print "Finished."