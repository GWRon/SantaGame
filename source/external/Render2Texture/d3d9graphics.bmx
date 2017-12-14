
Strict

Import BRL.Graphics

Import Pub.DirectX

Import BRL.LinkedList


Private

Global _wndClass$="BBDX9Device Window Class"

Global _driver:TD3D9graphicsDriver

Global _d3d:IDirect3D9
Global _d3dCaps:D3DCAPS9
Global _modes:TGraphicsMode[]

Global _d3dDev:IDirect3DDevice9
Global _d3dDevRefs

Global _presentParams:D3DPRESENT_PARAMETERS

Global _graphics:TD3D9Graphics

Global _autoRelease:TList

Global _d3dOccQuery:IDirect3DQuery9

Type TD3D9AutoRelease
	Field unk:IUnknown
End Type

Function D3D9WndProc( hwnd,msg,wp,lp ) "win32"
	bbSystemEmitOSEvent hwnd,msg,wp,lp,Null
	
	Select msg
	Case WM_CLOSE
		Return
	Case WM_SYSKEYDOWN
		If wp<>KEY_F4 Return
	Case WM_ACTIVATE
		If _graphics _graphics.OnWMActivate(wp)
		Return 0
	End Select

	Return DefWindowProcW( hwnd,msg,wp,lp )

End Function

Function OpenD3DDevice( hwnd,width,height,depth,hertz,flags )

	If _d3dDevRefs
		If Not _presentParams.Windowed Return False
		If depth<>0 Return False
		_d3dDevRefs:+1
		Return True
	EndIf

	Local windowed=(depth=0)
	Local fullscreen=(depth<>0)	

	Local pp:D3DPRESENT_PARAMETERS=New D3DPRESENT_PARAMETERS
	pp.BackBufferWidth=width
	pp.BackBufferHeight=height
	pp.BackBufferCount=1
	pp.BackBufferFormat=(D3DFMT_X8R8G8B8 * fullscreen) + (D3DFMT_UNKNOWN * windowed)
	pp.MultiSampleType=D3DMULTISAMPLE_NONE
	pp.SwapEffect=(D3DSWAPEFFECT_DISCARD * fullscreen) + (D3DSWAPEFFECT_COPY * windowed)
	pp.hDeviceWindow=hwnd
	pp.Windowed=windowed
	pp.Flags=D3DPRESENTFLAG_LOCKABLE_BACKBUFFER
	pp.FullScreen_RefreshRateInHz=(hertz * fullscreen)
	pp.PresentationInterval=D3DPRESENT_INTERVAL_ONE	'IMMEDIATE
	
	Function CheckDepthFormat(format)
	    Return _d3d.CheckDeviceFormat(0,D3DDEVTYPE_HAL,D3DFMT_X8R8G8B8,D3DUSAGE_DEPTHSTENCIL,D3DRTYPE_SURFACE,format)=D3D_OK
	End Function

	If flags&GRAPHICS_DEPTHBUFFER Or flags&GRAPHICS_STENCILBUFFER
	    pp.EnableAutoDepthStencil = True
	    If flags&GRAPHICS_STENCILBUFFER
	        If Not CheckDepthFormat( D3DFMT_D24S8 )
	            If Not CheckDepthFormat( D3DFMT_D24FS8 )
	                If Not CheckDepthFormat( D3DFMT_D24X4S4 )
	                    If Not CheckDepthFormat( D3DFMT_D15S1 )
	                        Return False
	                    Else
	                        pp.AutoDepthStencilFormat = D3DFMT_D15S1
	                    EndIf
	                Else
	                    pp.AutoDepthStencilFormat = D3DFMT_D24X4S4
	                EndIf
	            Else
	                pp.AutoDepthStencilFormat = D3DFMT_D24FS8
	            EndIf
	        Else
	            pp.AutoDepthStencilFormat = D3DFMT_D24S8
	        EndIf
	    Else
	        If Not CheckDepthFormat( D3DFMT_D32 )
	            If Not CheckDepthFormat( D3DFMT_D24X8 )
	                If Not CheckDepthFormat( D3DFMT_D16 )
	                    Return False
	                Else
	                    pp.AutoDepthStencilFormat = D3DFMT_D16
	                EndIf
	            Else
	                pp.AutoDepthStencilFormat = D3DFMT_D24X8
	            EndIf
	        Else
	            pp.AutoDepthStencilFormat = D3DFMT_D32
	        EndIf
	    EndIf
	EndIf
	
	Local cflags=D3DCREATE_FPU_PRESERVE
	
	'OK, try hardware vertex processing...
	Local tflags=D3DCREATE_PUREDEVICE|D3DCREATE_HARDWARE_VERTEXPROCESSING|cflags
	If _d3d.CreateDevice( 0,D3DDEVTYPE_HAL,hwnd,tflags,pp,_d3dDev )<0

		'Failed! Try mixed vertex processing...
		tflags=D3DCREATE_MIXED_VERTEXPROCESSING|cflags
		If _d3d.CreateDevice( 0,D3DDEVTYPE_HAL,hwnd,tflags,pp,_d3dDev )<0
	
			'Failed! Try software vertex processing...	
			tflags=D3DCREATE_SOFTWARE_VERTEXPROCESSING|cflags
			If _d3d.CreateDevice( 0,D3DDEVTYPE_HAL,hwnd,tflags,pp,_d3dDev )<0
			
				'Failed! Go home and watch family guy instead...
				Return False
			EndIf
		EndIf
	EndIf

	_presentParams=pp

	_d3dDevRefs:+1
	
	_autoRelease=New TList

	'Occlusion Query
	If Not _d3dOccQuery
		If _d3ddev.CreateQuery(9,_d3dOccQuery)<0 '9 hardcoded for D3DQUERYTYPE_OCCLUSION
			DebugLog "Cannot create Occlussion Query!"
		EndIf
	EndIf
	If _d3dOccQuery _d3dOccQuery.Issue(2) 'D3DISSUE_BEGIN
	
	Return True
End Function

Function CloseD3DDevice()
	_d3dDevRefs:-1
	If Not _d3dDevRefs

		For Local t:TD3D9AutoRelease=EachIn _autoRelease
			t.unk.Release_
		Next
		_autoRelease=Null

		If _d3dOccQuery _d3dOccQuery.Release_
		_d3dOccQuery = Null

		_d3dDev.Release_
		_d3dDev=Null
		_presentParams=Null
	EndIf
End Function

Function ResetD3DDevice()
	If _graphics _graphics.OnDeviceLost()
	If _d3dOccQuery _d3dOccQuery.Release_

	If _d3dDev.Reset( _presentParams ) < 0
		Throw "_d3dDev.Reset failed"
	EndIf

	If _graphics _graphics.OnDeviceReset()
	If _d3ddev.CreateQuery(9,_d3dOccQuery)<0
		DebugLog "Cannot create Occlussion Query!"
	EndIf
	If _d3dOccQuery _d3dOccQuery.Issue(2) 'D3DISSUE_BEGIN
		
End Function

Public

Global UseDX9RenderLagFix:Int = 0

Type TD3D9DeviceStateCallback
	Field _fnCallback(obj:Object)
	Field _obj:Object
	
	Method Create:TD3D9DeviceStateCallback(fnCallback(obj:Object), obj:Object)
		_fnCallback = fnCallback
		_obj = obj

		Return Self
	EndMethod
EndType

Type TD3D9Graphics Extends TGraphics
	Method New()
		_onDeviceLostCallbacks = New TList
		_onDeviceResetCallbacks = New TList
	EndMethod
	
	Method Attach:TD3D9Graphics( hwnd,flags )
		Local rect[4]
		GetClientRect hwnd,rect
		Local width=rect[2]-rect[0]
		Local height=rect[3]-rect[1]

		OpenD3DDevice hwnd,width,height,0,0,flags
		
		_hwnd=hwnd
		_width=width
		_height=height
		_flags=flags
		_attached=True
		Return Self
	End Method
	
	Method Create:TD3D9Graphics( width,height,depth,hertz,flags )
		Local wstyle

		If depth
			wstyle=WS_VISIBLE|WS_POPUP
		Else
			wstyle=WS_VISIBLE|WS_CAPTION|WS_SYSMENU|WS_MINIMIZEBOX
		EndIf
		
		Local rect[4]

		If Not depth
			Local desktopRect[4]
			GetWindowRect GetDesktopWindow(),desktopRect
				
			rect[0]=desktopRect[2]/2-width/2;		
			rect[1]=desktopRect[3]/2-height/2;		
			rect[2]=rect[0]+width;
			rect[3]=rect[1]+height;
				
			AdjustWindowRect rect,wstyle,0
		EndIf

		Local hwnd=CreateWindowExW( 0,_wndClass,AppTitle,wstyle,rect[0],rect[1],rect[2]-rect[0],rect[3]-rect[1],0,0,GetModuleHandleA(Null),Null )
		If Not hwnd Return Null

		If Not depth
			GetClientRect hwnd,rect
			width=rect[2]-rect[0]
			height=rect[3]-rect[1]
		EndIf
		
		If Not OpenD3DDevice( hwnd,width,height,depth,hertz,flags )
			DestroyWindow hwnd
			Return Null
		EndIf
		
		_hwnd=hwnd
		_width=width
		_height=height
		_depth=depth
		_hertz=hertz
		_flags=flags

		Return Self
	End Method
	
	Method OnWMActivate(wp:Int)
		' this covers the alt-tab issue for render-texture management
		Local activate:Short = wp & $FFFF
		Local state:Short = (wp Shr 16) & $FFFF
		
		' only release when fullscreen
		If activate = 0 And _depth <> 0
			OnDeviceLost()
		EndIf
		' the Flip(sync) method will call into ResetD3DDevice where OnDeviceReset will be called
	EndMethod
	
	Method AddDeviceLostCallback(fnOnDeviceLostCallback(obj:Object), obj:Object)
		_onDeviceLostCallbacks.AddLast(New TD3D9DeviceStateCallback.Create(fnOnDeviceLostCallback, obj))
	EndMethod
	
	Method AddDeviceResetCallback(fnOnDeviceResetCallback(obj:Object), obj:Object)
		_onDeviceResetCallbacks.AddLast(New TD3D9DeviceStateCallback.Create(fnOnDeviceResetCallback, obj))
	EndMethod
	
	Method RemoveDeviceLostCallback(fnOnDeviceLostCallback(obj:Object))
		For Local statecallback:TD3D9DeviceStateCallback = EachIn _onDeviceLostCallbacks
			If statecallback._fnCallback = fnOnDeviceLostCallback
				_onDeviceLostCallbacks.Remove(statecallback)
				Exit
			EndIf
		Next
	EndMethod

	Method RemoveDeviceResetCallback(fnOnDeviceResetCallback(obj:Object))
		For Local statecallback:TD3D9DeviceStateCallback = EachIn _onDeviceResetCallbacks
			If statecallback._fnCallback = fnOnDeviceResetCallback
				_onDeviceResetCallbacks.Remove(statecallback)
				Exit
			EndIf
		Next
	EndMethod

	Method OnDeviceLost()
		For Local callback:TD3D9DeviceStateCallback = EachIn _onDeviceLostCallbacks
			callback._fnCallback(callback._obj)
		Next
	EndMethod
	
	Method OnDeviceReset()
		For Local callback:TD3D9DeviceStateCallback = EachIn _onDeviceResetCallbacks
			callback._fnCallback(callback._obj)
		Next
	EndMethod
	
	Method GetDirect3DDevice:IDirect3DDevice9()
		Return _d3dDev
	End Method

	Method ValidateSize()
		If _attached
			Local rect[4]
			GetClientRect _hwnd,rect
			_width=rect[2]-rect[0]
			_height=rect[3]-rect[1]
			If _width>_presentParams.BackBufferWidth Or _height>_presentParams.BackBufferHeight
				_presentParams.BackBufferWidth=Max( _width,_presentParams.BackBufferWidth )
				_presentParams.BackBufferHeight=Max( _height,_presentParams.BackbufferHeight )
				ResetD3DDevice
			EndIf
		EndIf
	End Method
	
	'NOTE: Returns 1 if flip was successful, otherwise device lost or reset...
	Method Flip( sync )
	
		Local reset

		If sync sync=D3DPRESENT_INTERVAL_ONE Else sync=D3DPRESENT_INTERVAL_IMMEDIATE
		If sync<>_presentParams.PresentationInterval
			_presentParams.PresentationInterval=sync
			reset=True
		EndIf
		
		Select _d3dDev.TestCooperativeLevel()
		Case D3DERR_DRIVERINTERNALERROR
			Throw "D3D Internal Error"
		Case D3D_OK
			If reset

				ResetD3DDevice

			Else If _attached
			
				Local rect[]=[0,0,_width,_height]
				Return _d3dDev.Present( rect,rect,_hwnd,Null )>=0

			Else

				Return _d3dDev.Present( Null,Null,_hwnd,Null )>=0

			EndIf
		Case D3DERR_DEVICENOTRESET

			ResetD3DDevice

		End Select
		
		
	End Method

	Method Driver:TGraphicsDriver()
		Return _driver
	End Method
	
	Method GetSettings( width Var,height Var,depth Var,hertz Var,flags Var )
		'
		ValidateSize
		'
		width=_width
		height=_height
		depth=_depth
		hertz=_hertz
		flags=_flags
	End Method

	Method Close()
		If Not _hwnd Return
		CloseD3DDevice
		If Not _attached DestroyWindow( _hwnd )
		_hwnd=0
	End Method

	Method AutoRelease( unk:IUnknown )
		Local t:TD3D9AutoRelease=New TD3D9AutoRelease
		t.unk=unk
		_autoRelease.AddLast t
	End Method
	
	Method ReleaseNow( unk:IUnknown )
		For Local t:TD3D9AutoRelease=EachIn _autoRelease
			If t.unk=unk
				unk.Release_
				_autoRelease.Remove t
				Return
			EndIf
		Next
	End Method

	
	Field _hwnd
	Field _width
	Field _height
	Field _depth
	Field _hertz
	Field _flags
	Field _attached
	Field _onDeviceLostCallbacks:TList
	Field _onDeviceResetCallbacks:TList

End Type

Type TD3D9GraphicsDriver Extends TGraphicsDriver

	Method Create:TD3D9GraphicsDriver()
	
		'create d3d9
		If Not d3d9Lib Return Null
		
		_d3d=Direct3DCreate9( 32 )
		If Not _d3d Return Null
		
		'get caps
		_d3dCaps=New D3DCAPS9
		If _d3d.GetDeviceCaps( D3DADAPTER_DEFAULT,D3DDEVTYPE_HAL,_d3dCaps )<0
			_d3d.Release_
			_d3d=Null
			Return Null
		EndIf

		'enum graphics modes		
		Local n=_d3d.GetAdapterModeCount( D3DADAPTER_DEFAULT,D3DFMT_X8R8G8B8 )
		_modes=New TGraphicsMode[n]
		Local j
		For Local i=0 Until n
			Local d3dmode:D3DDISPLAYMODE=New D3DDISPLAYMODE

			If _d3d.EnumAdapterModes( D3DADAPTER_DEFAULT,D3DFMT_X8R8G8B8,i,d3dmode )<0
				Continue
			EndIf
			
			Local mode:TGraphicsMode=New TGraphicsMode
			mode.width=d3dmode.Width
			mode.height=d3dmode.Height
			mode.hertz=d3dmode.RefreshRate
			mode.depth=32
			
			_modes[j]=mode
			j:+1
		Next
		_modes=_modes[..j]
	
		'register wndclass
		Local wndclass:WNDCLASSW=New WNDCLASSW
		wndclass.hInstance=GetModuleHandleW( Null )
		wndclass.lpfnWndProc=D3D9WndProc
		wndclass.hCursor=LoadCursorW( Null,Short Ptr IDC_ARROW )
		wndclass.lpszClassName=_wndClass.ToWString()
		RegisterClassW wndclass
		MemFree wndclass.lpszClassName

		Return Self
	End Method
	
	Method GraphicsModes:TGraphicsMode[]()
		Return _modes
	End Method
	
	Method AttachGraphics:TD3D9Graphics( widget,flags )
		Return New TD3D9Graphics.Attach( widget,flags )
	End Method
	
	Method CreateGraphics:TD3D9Graphics( width,height,depth,hertz,flags )
		Return New TD3D9Graphics.Create( width,height,depth,hertz,flags )
	End Method
	
	Method Graphics:TD3D9Graphics()
		Return _graphics
	End Method
		
	Method SetGraphics( g:TGraphics )
		_graphics=TD3D9Graphics( g )
	End Method
	
	Method Flip( sync )
		Local present:Int = _graphics.Flip(sync)
		If UseDX9RenderLagFix Then
			Local pixelsdrawn:Int
			If _d3dOccQuery
				_d3dOccQuery.Issue(1) 'D3DISSUE_END
				
				While _d3dOccQuery.GetData( Varptr pixelsdrawn,4,1 )=1 'D3DGETDATA_FLUSH
					If  _d3dOccQuery.GetData( Varptr pixelsdrawn,4,1 )<0 Exit
				Wend

				_d3dOccQuery.Issue(2) 'D3DISSUE_BEGIN
			EndIf
		End If
		
		Return present
	End Method
	
	Method GetDirect3D:IDirect3D9()
		Return _d3d
	End Method
	
End Type

Function D3D9GraphicsDriver:TD3D9GraphicsDriver()
	Global _done
	If Not _done
		_driver=New TD3D9GraphicsDriver.Create()
		_done=True
	EndIf
	Return _driver
End Function
