Strict

Import BRL.D3D9Max2D
Import "renderimageinterface.bmx"

Type TD3D9RenderImageFrame Extends TD3D9ImageFrame
	Field _surface:IDirect3DSurface9
	Field _persistpixmap:TPixmap

	Method Delete()
		ReleaseNow()
	EndMethod
	
	Method ReleaseNow()
		If _surface
			_surface.Release_
			_surface = Null
		EndIf
		If _texture
			_texture.Release_
			_texture = Null
		EndIf
	EndMethod
	
	Method CreateRenderTarget:TD3D9RenderImageFrame( d3ddev:IDirect3DDevice9, width,height )
		d3ddev.CreateTexture(width,height,1,D3DUSAGE_RENDERTARGET,D3DFMT_A8R8G8B8,D3DPOOL_DEFAULT,_texture,Null)
		If _texture _texture.GetSurfaceLevel 0, _surface
		
		_magfilter = D3DTFG_LINEAR
		_minfilter = D3DTFG_LINEAR
		_mipfilter = D3DTFG_LINEAR

		_uscale = 1.0 / width
		_vscale = 1.0 / height

		Return Self
	EndMethod
	
	Method DestroyRenderImage()
		ReleaseNow()
	EndMethod

	Method OnDeviceLost(d3ddev:IDirect3DDevice9, width:Int, height:Int)
		_persistpixmap = ToPixmap(d3ddev, width, height)
		ReleaseNow()
	EndMethod

	Method OnDeviceReset(d3ddev:IDirect3DDevice9)
		Local width:Int = _persistpixmap.width
		Local height:Int = _persistpixmap.height

		d3ddev.CreateTexture(width, height, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, _texture, Null)
		If _texture _texture.GetSurfaceLevel(0, _surface)

		' use a staging surface to copy the pixmap into
		Local stage:IDirect3DSurface9
		d3ddev.CreateOffscreenPlainSurface(width, height, D3DFMT_A8R8G8B8, D3DPOOL_SYSTEMMEM, stage, Null)

		Local lockedrect:D3DLOCKED_RECT = New D3DLOCKED_RECT
		stage.LockRect(lockedrect, Null, 0)

		' copy the pixel data across
		For Local y:Int = 0 Until _persistpixmap.height
			Local srcptr:Byte Ptr = _persistpixmap.pixels + y * _persistpixmap.pitch
			Local dstptr:Byte Ptr = lockedrect.pBits + y * lockedrect.Pitch
			MemCopy dstptr, srcptr, _persistpixmap.width * 4
		Next
		stage.UnlockRect()

		' copy from the staging surface to the render surface
		d3ddev.UpdateSurface(stage, Null, _surface, Null)

		' cleanup
		stage.release_
		_persistpixmap = Null
	EndMethod
	
	Method ToPixmap:TPixmap(d3ddev:IDirect3DDevice9, width:Int, height:Int)
		Local pixmap:TPixmap = CreatePixmap(width, height, PF_RGBA8888)

		' use a staging surface to get the texture contents
		Local stage:IDirect3DSurface9
		d3ddev.CreateOffscreenPlainSurface(width, height, D3DFMT_A8R8G8B8, D3DPOOL_SYSTEMMEM, stage, Null)

		If d3ddev.GetRenderTargetData(_surface, stage) < 0 Throw "TD3D9RenderImageFrame:ToPixmap:GetRenderTargetData failed"

		' copy the pixel data across
		Local lockedrect:D3DLOCKED_RECT = New D3DLOCKED_RECT
		If stage.LockRect(lockedrect, Null, 0) < 0 Throw "TD3D9RenderImageFrame:ToPixmap:LockRect failed"

		For Local y:Int = 0 Until pixmap.height
			For Local x:Int = 0 Until pixmap.width
				Local srcptr:Int Ptr = Int Ptr (lockedrect.pBits + x * 4 + y * lockedrect.Pitch)
				Local dstptr:Int Ptr = Int Ptr (pixmap.pixels + x * 4 + y * pixmap.pitch)
				dstptr[0] = ((srcptr[0] & $ff) Shl 16) | ((srcptr[0] & $ff0000) Shr 16)| (srcptr[0] & $ff00) | (srcptr[0] & $ff000000)
			Next
		Next
		
		' cleanup
		stage.UnlockRect()
		stage.release_
		
		Return pixmap
	EndMethod
EndType

Type TD3D9RenderImage Extends TRenderImage
	Field _d3ddev:IDirect3DDevice9
	Field _viewport:D3DVIEWPORT9
	Field _matrix:Float[]

	Method Delete()
		ReleaseNow()
	EndMethod
	
	Method ReleaseNow()
		If _d3ddev
			_d3ddev.release_
			_d3ddev = Null
		EndIf
	EndMethod

	Method CreateRenderImage:TD3D9RenderImage(width:Int ,height:Int)
		Self.width=width	' TImage.width
		Self.height=height	' TImage.height
	
		_matrix = [	2.0/width, 0.0, 0.0, 0.0,..
					0.0, -2.0/height, 0.0, 0.0,..
					0.0, 0.0, 1.0, 0.0,..
					-1-(1.0/width), 1+(1.0/height), 1.0, 1.0 ]

		_viewport = New D3DVIEWPORT9
		_viewport.width = width
		_viewport.height = height
		_viewport.MaxZ = 1.0

		Return Self
	EndMethod
	
	Method DestroyRenderImage()
		ReleaseNow()
		TD3D9RenderImageFrame(frames[0]).ReleaseNow()
	EndMethod

	Method Init(d3ddev:IDirect3DDevice9, UseImageFiltering:Int)
		_d3ddev = d3ddev
		_d3ddev.AddRef()

		frames = New TD3D9RenderImageFrame[1]
		frames[0] = New TD3D9RenderImageFrame.CreateRenderTarget(d3ddev, width, height)
		If UseImageFiltering
			TD3D9RenderImageFrame(frames[0])._magfilter=D3DTFG_LINEAR
			TD3D9RenderImageFrame(frames[0])._minfilter=D3DTFG_LINEAR
			TD3D9RenderImageFrame(frames[0])._mipfilter=D3DTFG_LINEAR
		Else
			TD3D9RenderImageFrame(frames[0])._magfilter=D3DTFG_POINT
			TD3D9RenderImageFrame(frames[0])._minfilter=D3DTFG_POINT
			TD3D9RenderImageFrame(frames[0])._mipfilter=D3DTFG_POINT
		EndIf


		'  clear the new render target surface
		Local prevsurf:IDirect3DSurface9
		Local prevmatrix:Float[16]
		Local prevviewport:D3DVIEWPORT9 = New D3DVIEWPORT9
		' get previous
		d3ddev.GetRenderTarget(0, prevsurf)
		d3ddev.GetTransform(D3DTS_PROJECTION, prevmatrix)
		d3ddev.GetViewport(prevviewport)

		' set and clear
		d3ddev.SetRenderTarget(0, TD3D9RenderImageFrame(frames[0])._surface)
		d3ddev.SetTransform(D3DTS_PROJECTION, _matrix)
		d3ddev.Clear(0, Null, D3DCLEAR_TARGET, 0, 0.0, 0)

		' reset to previous
		_d3ddev.SetRenderTarget(0, prevsurf)
		_d3ddev.SetTransform(D3DTS_PROJECTION, prevmatrix)
		_d3ddev.SetViewport(prevviewport)

		' cleanup
		prevsurf.release_
	EndMethod

	Method Frame:TImageFrame(index=0)
		If Not frames Return Null
		If Not frames[0] Return Null
		Return frames[0]
	EndMethod
	
	Method SetRenderImage()
		Local pTexture:IDirect3DTexture9
		_d3ddev.GetTexture(0, pTexture)
		
		Local frame:TD3D9RenderImageFrame = TD3D9RenderImageFrame(frames[0])
		If frame._texture <> pTexture
			_d3ddev.SetTexture(0, pTexture)
		EndIf
		
		If pTexture pTexture.Release_
		
		_d3ddev.SetRenderTarget(0, TD3D9RenderImageFrame(frames[0])._surface)
		_d3ddev.SetTransform(D3DTS_PROJECTION,_matrix)
		_d3ddev.SetViewport(_viewport)
	EndMethod
	
	Method ToPixmap:TPixmap()
		Return TD3D9RenderImageFrame(frames[0]).ToPixmap(_d3ddev, width, height)
	EndMethod
	
	Method SetViewport(x:Int, y:Int, width:Int, height:Int)
		If x = 0 And y = 0 And width = Self.width And height = Self.height
			_d3ddev.SetRenderState(D3DRS_SCISSORTESTENABLE, False)
		Else
			_d3ddev.SetRenderState(D3DRS_SCISSORTESTENABLE, True)
			Local rect[] = [x , y, x + width, y + height]
			_d3ddev.SetScissorRect(rect)
		EndIf

	EndMethod

	Method OnDeviceLost()
		TD3D9RenderImageFrame(frames[0]).OnDeviceLost(_d3ddev, width, height)
	EndMethod

	Method OnDeviceReset()
		TD3D9RenderImageFrame(frames[0]).OnDeviceReset(_d3ddev)
	EndMethod
EndType





