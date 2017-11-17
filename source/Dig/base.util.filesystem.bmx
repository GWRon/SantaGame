SuperStrict

Import Brl.Stream
?android
Import Sdl.Sdl
?not android
Import brl.filesystem
?

Type FileSystem
	Function FileSize:Long(uri:string)
		?android
			local s:TStream = CreateStream(uri, True, False)
			if not s then return 0
			local size:Long = s.Size()
			s.Close()
			return s
		?not android
			'use brl one
			return .FileSize(uri:string)
		?
	End Function
End Type