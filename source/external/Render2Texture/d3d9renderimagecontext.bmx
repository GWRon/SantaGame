
Strict

Import "renderimagecontextinterface.bmx"
Import "d3d9renderimage.bmx"

Type TD3D9RenderImageContext Extends TRenderImageContext
	Field _gc:TD3D9Graphics
	Field _d3ddev:IDirect3DDevice9
	Field _backbuffer:IDirect3DSurface9
	Field _matrix:Float[16]
	Field _viewport:D3DVIEWPORT9
	Field _renderimages:TList
	Field _deviceok:Int = True

	Method Delete()
		ReleaseNow()
	EndMethod
	
	Method ReleaseNow()
		If _renderimages
			For Local ri:TD3D9RenderImage = EachIn _renderimages
				ri.DestroyRenderImage()
			Next
		EndIf

		_renderimages = Null
		_viewport = Null
		_gc = Null

		If _backbuffer
			_backbuffer.release_
			_backbuffer = Null
		EndIf
		If _d3ddev
			_d3ddev.release_
			_d3ddev = Null
		EndIf
	EndMethod

	Method Create:TD3D9RenderimageContext(context:TGraphics)
		Local gc:TD3D9Graphics = TD3D9Graphics(context)
		_gc = gc

		gc.AddDeviceLostCallback(fnOnDeviceLost, Self)
		gc.AddDeviceResetCallback(fnOnDeviceReset, Self)

		_d3ddev = gc.GetDirect3DDevice()
		_d3ddev.AddRef()

		_d3ddev.GetRenderTarget(0, _backbuffer)

		_viewport = New D3DVIEWPORT9
		_d3ddev.GetViewport(_viewport)
		_d3ddev.GetTransform(D3DTS_PROJECTION, _matrix)
			
		_renderimages = New TList

		Return Self
	EndMethod
	
	Method GraphicsContext:TGraphics()
		Return _gc
	EndMethod
	
	Method Destroy()
		_gc.RemoveDeviceLostCallback(fnOnDeviceLost)
		_gc.RemoveDeviceResetCallback(fnOnDeviceReset)
		ReleaseNow()
	EndMethod

	Method CreateRenderImage:TRenderImage(width:Int, height:Int, UseImageFiltering:Int)
		Local renderimage:TD3D9RenderImage = New TD3D9RenderImage.CreateRenderImage(width, height)
		renderimage.Init(_d3ddev, UseImageFiltering)
		_renderimages.AddLast(renderimage)

		Return renderimage
	EndMethod
	
	Method DestroyRenderImage(renderImage:TRenderImage)
		renderImage.DestroyRenderImage()
		_renderimages.Remove(renderImage)
	EndMethod

	Method SetRenderImage(renderimage:TRenderimage)
		If Not renderimage
			_d3ddev.SetRenderTarget(0, _backbuffer)	
			_d3ddev.SetTransform D3DTS_PROJECTION,_matrix
			_d3ddev.SetViewport(_viewport)
		Else
			renderimage.SetRenderImage()
		EndIf
	EndMethod
	
	Method CreatePixmapFromRenderImage:TPixmap(renderImage:TRenderImage)
		Return TD3D9RenderImage(renderImage).ToPixmap()
	EndMethod

	Method OnDeviceLost()
		If _deviceok = False Return

		For Local ri:TD3D9RenderImage = EachIn _renderimages
			ri.OnDeviceLost()
		Next
		If _backbuffer
			_backbuffer.release_
			_backbuffer = Null
		EndIf

		_deviceok = False
	EndMethod

	Method OnDeviceReset()
		If _deviceok = True Return

		Local hr:Int = _d3ddev.GetRenderTarget(0, _backbuffer)
		hr = _d3ddev.GetViewport(_viewport)

		For Local ri:TD3D9RenderImage = EachIn _renderimages
			ri.OnDeviceReset()
		Next

		_deviceok = True
	EndMethod

	Function fnOnDeviceLost(obj:Object)
		Local ric:TD3D9RenderImageContext = TD3D9RenderImageContext(obj)
		If Not ric Return
		ric.OnDeviceLost()
	EndFunction

	Function fnOnDeviceReset(obj:Object)
		Local ric:TD3D9RenderImageContext = TD3D9RenderImageContext(obj)
		If Not ric Return
		ric.OnDeviceReset()
	EndFunction
EndType
