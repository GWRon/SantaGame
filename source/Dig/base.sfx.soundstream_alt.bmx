REM
	====================================================================
	Audio Stream Classes
	====================================================================

	Contains:

	- a manager "TDigAudioStreamManager" needed for regular updates of
	  audio streams (refill of buffers). If not used, take care to
	  manually call "update()" for each stream on a regular base. 
	- a basic stream class "TDigAudioStream" and its extension
	  "TDigAudioStreamOgg" to enable decoding of ogg files.



	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2014 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
ENDREM
SuperStrict
Import pub.freeaudio
Import Pub.OggVorbis
Import Brl.OggLoader
Import Brl.LinkedList
Import Brl.audio
Import Brl.freeaudioaudio
Import Brl.standardio
Import Brl.bank
Import "base.sfx.soundstream.c"


Extern
	Function StartDigAudioStreamManagerUpdateThread:Int()
	Function StopDigAudioStreamManagerUpdateThread:Int()

	Function RegisterDigAudioStreamManagerUpdateCallback( func() )
	Function RegisterDigAudioStreamManagerPrintCallback( func(chars:Byte Ptr) )
End Extern




Type TDigAudioStreamManager
	Field streams:TList = CreateList()
	Global externalThreadRunning:int = False


	Method Init()
		print "TDigAudioStreamManager.Init()"
		if not externalThreadRunning and 1 = 2
			print "  setting update callback"
			'register callbacks to C - should be done in manager
			RegisterDigAudioStreamManagerUpdateCallback( cbStreamUpdate )
			print "  setting print callback"
			RegisterDigAudioStreamManagerPrintCallback( cbPrint )

			print "  starting update thread"
			StartDigAudioStreamManagerUpdateThread()
			externalThreadRunning = True
		endif
	End Method


	Method AddStream:int(stream:TDigAudioStream)
		streams.AddLast(stream)
		return True
	End Method


	Method RemoveStream:int(stream:TDigAudioStream)
		streams.Remove(stream)
		return True
	End Method


	Method ContainsStream:int(stream:TDigAudioStream)
		return streams.Contains(stream)
	End Method


	'do not call this manually except you know what you do
	Method Update:int()
		For local stream:TDigAudioStream = eachin streams
			stream.Update()
		Next
	End Method


	Function cbPrint:int(chars:Byte Ptr)
		print String.FromCString(chars)
	End Function


	global firstRun:int = Millisecs()
	Function cbStreamUpdate:Int()
		if not DigAudioStreamManager then return False

		DigAudioStreamManager.Update()

		Return MilliSecs()
	End Function
End Type
Global DigAudioStreamManager:TDigAudioStreamManager = new TDigAudioStreamManager




'base class for audio streams
Type TDigAudioStream
	Field buffer:int[]
	Field sound:TSound
	Field currentChannel:TChannel

	Field streamPosition:int
	Field streaming:int
	'channel position might differ from the really played position
	'so better store a custom position property to avoid discrepancies
	'when pausing a stream
	Field playbackPosition:int
	'temporary variable to calculate position changes since last update
	Field _lastPlaybackPosition:int
	Field _lastHandledBufferIndex:int = -1
	Field _channelStartPosition:int = 0

	'length of the total sound
	Field samplesCount:int = 0

	Field bits:int = 16
	Field freq:int = 44100
	Field channels:int = 2
	Field format:int = 0
	Field loop:int = False
	Field paused:int = False
	Field bufferStates:int[]

	'length of each chunk in positions/ints 
	Const chunkLength:int = 1024
	'amount of chunks in one buffer
	Const bufferChunkCount:int = 16
	'amount of buffers
	Const bufferCount:int = 3
	Const BUFFER_STATE_UNUSED:int = 0
	Const BUFFER_STATE_PLAYING:int = 1
	Const BUFFER_STATE_BUFFERED:int = 2


	Method Create:TDigAudioStream(loop:int = False)
		?PPC
		If channels=1 Then format=SF_MONO16BE Else format=SF_STEREO16BE
		?X86
		If channels=1 Then format=SF_MONO16LE Else format=SF_STEREO16LE
		?

		'option A
		'audioSample = CreateAudioSample(GetBufferLength(), freq, format)

		'option B
		self.buffer = new Int[GetTotalBufferLength()]
		local audioSample:TAudioSample = CreateStaticAudioSample(Byte Ptr(buffer), GetTotalBufferLength(), freq, format)

		bufferStates = new Int[bufferCount]

		'driver specific sound creation
		CreateSound(audioSample)
	
		SetLooped(loop)

		return Self
	End Method


	Method Clone:TDigAudioStream(deepClone:int = False)
		local c:TDigAudioStream = new TDigAudioStream.Create(self.loop)
		return c
	End Method


	'=== CONTAINING FREE AUDIO SPECIFIC CODE ===

	Method CreateSound:int(audioSample:TAudioSample)
		'not possible as "Loadsound"-flags are not given to
		'fa_CreateSound, but $80000000 is needed for dynamic sounds
		rem
			$80000000 = "dynamic" -> dynamic sounds stay in app memory
			sound = LoadSound(audioSample, $80000000)
		endrem

		'LOAD FREE AUDIO SOUND
		Local fa_sound:int = fa_CreateSound( audioSample.length, bits, channels, freq, audioSample.samples, $80000000 )
		sound = TFreeAudioSound.CreateWithSound( fa_sound, audioSample)
	End Method


	Method CreateChannel:TChannel(volume:Float)
		Reset()
		currentChannel = Cue()
		currentChannel.SetVolume(volume)
		Return currentChannel
	End Method


	Method GetChannel:TChannel()
		return currentChannel
	End Method
	

	Method GetChannelPosition:int()
		'to recognize if the buffer needs a new refill, the position of
		'the current playback is needed. TChannel does not provide that
		'functionality, streaming with it is not possible that way.
		if TFreeAudioChannel(currentChannel)
			return TFreeAudioChannel(currentChannel).Position()
		endif
		return 0
	End Method

	'=== / END OF FREE AUDIO SPECIFIC CODE ===


	Method GetTotalBufferSize:int()
		return GetTotalBufferLength() * channels * 2
	End Method


	Method GetTotalBufferLength:int()
		return GetBufferLength() * bufferCount
	End Method


	Method GetTotalBufferChunkCount:int()
		return GetBufferChunkCount() * bufferCount
	End Method


	Method GetBufferChunkCount:int()
		return bufferChunkCount
	End Method


	Method GetBufferLength:int()
		return chunkLength * GetBufferChunkCount()
	End Method


	Method GetBufferIndex:int(position:int = -1)
		return (position / Float(GetTotalBufferLength())) * bufferCount
	End Method


	'returns the buffer index of the play position
	Method GetBufferPlayIndex:int()
		return GetBufferIndex( GetTotalBufferPlayPosition() )
	End Method


	'returns the buffer index of the write position
	Method GetBufferWriteIndex:int()
		return GetBufferIndex( GetTotalBufferWritePosition() )
	End Method
	

	Method GetPlaybackPosition:int()
		return playbackPosition
	End Method


	'returns current write position within the complete buffer
	Method GetTotalBufferWritePosition:int()
		return streamPosition mod GetTotalBufferLength()
	End Method


	'returns current write position within the (single) buffer
	Method GetBufferWritePosition:int()
		return GetTotalBufferWritePosition() mod GetBufferLength()
	End Method


	'returns the position of the currently played data
	Method GetTotalBufferPlayPosition:int()
		return GetChannelPosition() mod GetTotalBufferLength()
	End Method


	'returns the position of the currently played data within the
	'(single) buffer
	Method GetBufferPlayPosition:int()
		return GetTotalBufferPlayPosition() mod GetBufferLength()
	End Method


	Method GetTimeLeft:float()
		return (samplesCount - GetPlaybackPosition()) / float(freq)
	End Method


	Method GetTimePlayed:float()
		return GetPlaybackPosition() / float(freq)
	End Method
	

	Method GetTimeBuffered:float()
		return (GetPlaybackPosition() + GetBufferWritePosition()) / float(freq)
	End Method


	Method GetTimeTotal:int()
		return samplesCount / freq
	End Method


	Method GetProgress:Float()
		if samplesCount = 0 then return 0
		return GetPlaybackPosition() / Float(samplesCount)
	End Method


	Method GetLength:int()
		return samplesCount
	End Method
	

	Method Delete()
		'int arrays get cleaned without our help
		'so only free the buffer if it was MemAlloc'ed 
		'if GetBufferSize() > 0 then MemFree buffer
	End Method


	Method ReadyToPlay:int()
		return Not streaming And GetBufferWritePosition() >= GetBufferLength()
	End Method


	Method EmptyBuffer:int(offset:int, length:int = -1)
	End Method


	Method FillBuffer:int(offset:int, length:int = -1)
	End Method


	'begin again
	Method Reset:int()
		streamPosition = 0
		playbackPosition = 0
		_lastPlaybackPosition = 0
		_lastHandledBufferIndex = -1
		streaming = False
	End Method


	Method GetName:string()
		return "unknown (TDigAudioStream)"
	End Method


	Method IsPaused:int()
		'we cannot use "channelStatus & PAUSED" as the channel gets not
		'paused but the stream!
		'16 is the const "PAUSED" in freeAudio
		'return (fa_ChannelStatus(faChannel) & 16)

		return paused
	End Method


	Method PauseStreaming:int(bool:int = True)
		paused = bool
		GetChannel().SetPaused(bool)
	End Method


	Method SetLooped(bool:int = True)
		loop = bool
	End Method


	Method FinishPlaying:int()
		print "FinishPlaying: " + GetName()
		Reset()
		PauseStreaming()
	End Method


	Method Play:TChannel(reUseChannel:TChannel = null)
		print "Play: " + GetName()

		'load initial buffer - preload + playback buffer
		FillBuffer(0, GetBufferLength())
		'_lastBufferIndex = bufferCount
		print "  Loaded initial buffer"


		'init and start threads if not done yet
		DigAudioStreamManager.Init()
		
		if not DigAudioStreamManager.ContainsStream(self)
			DigAudioStreamManager.AddStream(self)
		endif

		if not reUseChannel then reUseChannel = currentChannel
		currentChannel = PlaySound(sound, reUseChannel)

		 _channelStartPosition = GetChannelPosition()

		return currentChannel
	End Method


	Method Cue:TChannel(reUseChannel:TChannel = null)
		if not reUseChannel then reUseChannel = currentChannel
		currentChannel = CueSound(sound, reUseChannel)

		 _channelStartPosition = GetChannelPosition()

		return currentChannel
	End Method


	Method Update()
		if isPaused() then return
		if currentChannel and not currentChannel.Playing() then return

		'=== CALCULATE STREAM-PLAYBACK POSITION ===
		playbackPosition :+ GetChannelPosition() - _channelStartPosition - _lastPlaybackPosition
		playbackPosition = Min(samplesCount, playbackPosition)
'		if playbackPosition - _lastPlaybackPosition > 2* GetBufferLength()
'			print "SKIPPED MORE THAN THE BUFFER " + playbackPosition
'		endif
		_lastPlaybackPosition = playbackPosition
print "update  " + playbackPosition + " / " + samplesCount
		'nothing to do
		if GetBufferIndex(playbackPosition) = _lastHandledBufferIndex then print "skip"; return
		_lastHandledBufferIndex = GetBufferIndex(playbackPosition)

		'print "Update: "+ GetName()



		'=== FINISH PLAYBACK IF END IS REACHED ===
		'did the playing position reach the last piece of the stream?
		if GetPlaybackPosition() >= samplesCount and not loop
			FinishPlaying()
			return
		endif

'		For local i:int = 0 until bufferCount
'			print bufferStates[i]
'		Next

		'refresh bufferstates
		local unusedCount:int = 0
		For local i:int = 0 until bufferCount
			if GetBufferPlayIndex() <> i
				if bufferStates[i] = BUFFER_STATE_PLAYING
					bufferStates[i] = BUFFER_STATE_UNUSED
				endif
			elseif bufferStates[i] <> BUFFER_STATE_PLAYING
				bufferStates[i] = BUFFER_STATE_PLAYING
			endif

			unusedCount :+ 1
		Next

		'no buffer for refill available
		if unusedCount = 0 then print "NOTHING TO DO";return


		for local i:int = 0 until bufferCount
			'for playIndex = 1 this is: 2, 0
			'for playIndex = 2 this is: 0, 1
			local index:int = (GetBufferPlayIndex() + i + 1) mod bufferCount

			if bufferStates[ index ] <> BUFFER_STATE_UNUSED then continue
			
	
			local loadSize:int = Min( GetBufferLength() , samplesCount - streamPosition)
			if loadSize > 0
				FillBuffer(GetTotalBufferWritePosition(), loadSize)

				'wasn't enough data for the buffer?
				'-> fill with silence or repeat
				if loadSize <> GetBufferLength()
					if loop
						print "reset offset=" + GetTotalBufferWritePosition() +" size="+(GetBufferLength() - loadsize)
						Reset()
						FillBuffer(GetTotalBufferWritePosition(), GetBufferLength() - loadsize)
						'adjust channel start position
						'_channelStartPosition = GetChannelPosition()
						_channelStartPosition :+ GetTotalBufferWritePosition() + (GetBufferLength() - loadsize)
						'playbackPosition = GetBufferLength() - loadsize
					else
						print "empty buffer"
						EmptyBuffer(GetTotalBufferWritePosition(), GetBufferLength() - loadsize)
					endif
				endif
					

				bufferStates[ index ] = BUFFER_STATE_BUFFERED
			endif

			'reached end - reset stream and start again
			if loadSize = 0
				print "RESET: " + (samplesCount - streamPosition) 
				Reset()
			endif
		Next
rem
		print "Update: "+GetBufferWriteIndex()+" - "+GetBufferPlayIndex()
		'index numbers: 0-2
		Select GetBufferWriteIndex() - GetBufferPlayIndex()
			case 3
				Throw "ups"
				print "sollte nicht passieren"
				
			'- 0: both at the begin - load 1 + 2
			'- 2: at least 2 buffers behind 
			case 0, 2
				'begin ?
'				if GetBufferWriteIndex() = 0
					chunksToLoad = 2 * GetBufferLength() / chunkLength
					print "load Buffer "+((GetBufferWriteIndex()+1) mod 3) +" + " + ((GetBufferWriteIndex()+2) mod 3)
'				endif
			case 1, -1, -2
				chunksToLoad = 1 * GetBufferLength() / chunkLength
				print "load Buffer " + ((GetBufferWriteIndex()+1) mod 3)
			default
				print "nothing to do"
				return
		End Select
		if chunksToLoad = 0 then return
endrem		

		'=== LOAD NEW CHUNKS / BUFFER DATA ===
		'Local chunksToLoad:int = (GetBufferLength() - GetBufferWritePosition()) / chunkLength	
'print "  Stream: playPosition = " + GetPosition()+"/"+GetLength() + "   " +  (100*GetProgress()+"%")
'print "  Stream: streamPosition = " + streamPosition+"/"+GetLength()
'print "  Buffer: playPosition = " + GetBufferPlayPosition() + "/" + GetTotalBufferLength()
'print "  Buffer: writePosition = " + GetBufferWritePosition() + "/" + GetBufferLength() + "   " + GetTotalBufferWritePosition() +"/" + GetTotalBufferLength()
'print "  Buffer: writeIndex = " + GetBufferWriteIndex() + "   playIndex = " + GetBufferPlayIndex()
'print "  Buffer: chunksToLoad = " + chunksToLoad
		'looping this way (in blocks of 1024) means that no "wrap over"
		'can occour (start at 7168 and add 2048 - which wraps over 8192)
rem
		While chunksToLoad > 0 and streamPosition < samplesCount
			local loadSize:int = Min(chunksToLoad * chunkLength, samplesCount - streamPosition)
			print "    FillBuffer: chunksToLoad = " + chunksToLoad +"  bufferOffset = " + GetBufferWritePosition() +"  streamPosition = "+streamPosition
'			FillBuffer(GetBufferWritePosition(), loadSize)
			streamPosition :+ loadSize

			'chunksToLoad :- 1
			chunksToLoad = 0
		Wend
endrem
		'=== BEGIN PLAYBACK IF BUFFERED ENOUGH ===
		if ReadyToPlay() and not IsPaused()
print "  Set streaming to true"
			if currentChannel then currentChannel.SetPaused(False)
			streaming = True
		endif
	End Method
End Type



'extended audio stream to allow ogg file streaming
Type TDigAudioStreamOgg extends TDigAudioStream
	Field stream:TStream
	Field bank:TBank
	Field uri:object
	Field ogg:Byte Ptr
	

	Method Create:TDigAudioStreamOgg(loop:int = False)
		Super.Create(loop)

		return Self
	End Method


	Method CreateWithFile:TDigAudioStreamOgg(uri:object, loop:int = False, useMemoryStream:int = False)
		self.uri = uri
		'avoid file accesses and load file into a bank
		if useMemoryStream
			SetMemoryStreamMode()
		else
			SetFileStreamMode()
		endif
		
		Reset()
	
		Create(loop)
		return self
	End Method


	Method Clone:TDigAudioStreamOgg(deepClone:int = False)
		local c:TDigAudioStreamOgg = new TDigAudioStreamOgg.Create(self.loop)
		c.uri = self.uri
		if self.bank
			if deepClone
				c.bank = LoadBank(self.bank)
				c.stream = OpenStream(c.bank)
			'save memory and use the same bank
			else
				c.bank = self.bank
				c.stream = OpenStream(c.bank)
			endif
		else
			c.stream = OpenStream(c.uri)
		endif

		c.Reset()
		
		return c
	End Method


	Method SetMemoryStreamMode:int()
		bank = LoadBank(uri)
		stream = OpenStream(bank)
	End Method


	Method SetFileStreamMode:int()
		stream = OpenStream(uri)
	End Method


	'move to start, (re-)generate pointer to decoded ogg stream 
	Method Reset:int()
		if not stream then return False
		Super.Reset()

		'return to begin of raw data stream
		stream.Seek(0)

		'generate pointer object to decoded ogg stream
		ogg = Decode_Ogg(stream, readfunc, seekfunc, closefunc, tellfunc, samplesCount, channels, freq)
		If Not ogg Return False

		Return True
	End Method


	Method GetName:string()
		return string(uri)+" (TDigAudioStreamOgg)"
	End Method


	Method EmptyBuffer(offset:int, length:int = -1)
		'length is given in "ints", so calculate length in bytes
		local bytes:int = 4 * length
		If bytes > GetTotalBufferSize() then bytes = GetTotalBufferSize()

		local bufAppend:Byte Ptr = Byte Ptr(buffer) + offset*4

		For local i:byte = 0 to bytes
			bufAppend[i] = 0
		Next
	End Method
	

	Method FillBuffer:int(offset:int, length:int = -1)
		If Not ogg then Return False

		'=== PROCESS PARAMS === 
		'do not read more than available
		length = Min(length, (samplesCount - streamPosition))
		if length <= 0 then Return False

		'length is given in "ints", so calculate length in bytes
		local bytes:int = 4 * length
		If bytes > GetTotalBufferSize() then bytes = GetTotalBufferSize()


		'=== FILL IN DATA ===
		local bufAppend:Byte Ptr = Byte Ptr(buffer) + offset*4
		'try to read the oggfile at the current position
		Local err:int = Read_Ogg(ogg, bufAppend, bytes)
		if err
			Print "Error streaming from OGG"
			Throw "Error streaming from OGG"
		endif

		streamPosition :+ length

		return True
	End Method


	'adjusted from brl.mod/oggloader.mod/oggloader.bmx
	'they are "private" there... so this is needed to expose them
	Function readfunc:int( buf:Byte Ptr, size:int, nmemb:int, src:Object )
		Return TStream(src).Read(buf, size * nmemb) / size
	End Function


	Function seekfunc:int(src_obj:Object, off0:int, off1:int, whence:int)
		Local src:TStream=TStream(src_obj)
	?X86
		Local off:int = off0
	?PPC
		Local off:int = off1
	?
		Local res:int = -1
		Select whence
			Case 0 'SEEK_SET
				res = src.Seek(off)
			Case 1 'SEEK_CUR
				res = src.Seek(src.Pos()+off)
			Case 2 'SEEK_END
				res = src.Seek(src.Size()+off)
		End Select
		If res >= 0 Then Return 0
		Return -1
	End Function


	Function closefunc(src:Object)
		
	End Function
	

	Function tellfunc:int(src:Object)
		Return TStream(src).Pos()
	End Function
End Type
