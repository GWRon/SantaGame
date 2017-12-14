
Strict

Import "renderimagecontextinterface.bmx"
Import "d3d11renderimage.bmx"

Type TD3D11RenderImageContext Extends TRenderImageContext
	Field _gc:TD3D11Graphics
	Field _d3ddev:ID3D11Device
	Field _d3ddevcon:ID3D11DeviceContext
	Field _backbuffer:ID3D11RenderTargetView
	Field _viewport:D3D11_VIEWPORT
	Field _matrixbuffer:ID3D11Buffer
	
	Field _samplerPoint:ID3D11SamplerState
	Field _samplerLinear:ID3D11SamplerState

	Field _renderimages:TList

	Method Delete()
		ReleaseNow()
	EndMethod

	Method ReleaseNow()
		If _renderimages
			For Local ri:TD3D11RenderImage = EachIn _renderimages
				ri.DestroyRenderImage()
			Next
		EndIf

		_renderimages = Null
		_viewport = Null
		_gc = Null

		If _samplerPoint
			_samplerPoint.release_
			_samplerPoint = Null
		EndIf
		If _samplerLinear
			_samplerLinear.release_
			_samplerLinear = Null
		EndIf
		If _backbuffer
			_backbuffer.release_
			_backbuffer = Null
		EndIf
		If _matrixbuffer
			_matrixbuffer.release_
			_matrixbuffer = Null
		EndIf
		If _d3ddevcon
			_d3ddevcon.release_
			_d3ddevcon = Null
		EndIf
		If _d3ddev
			_d3ddev.release_
			_d3ddev = Null
		EndIf
	EndMethod

	Method Create:TD3D11RenderimageContext(context:TGraphics)
		_gc = TD3D11Graphics(context)

		_d3ddev = _gc.GetDirect3DDevice()
		_d3ddev.AddRef()

		_d3ddevcon = _gc.GetDirect3DDeviceContext()
		_d3ddevcon.AddRef()		

		_d3ddevcon.OMGetRenderTargets(1, Varptr _backbuffer, Null)	
		_d3ddevcon.VSGetConstantBuffers(0, 1, Varptr _matrixbuffer)

		_viewport = New D3D11_VIEWPORT
		Local vpCount:Int = 1

		_d3ddevcon.RSGetViewports(vpCount, _viewport)
		_renderimages = New TList
		
		Local sd:D3D11_SAMPLER_DESC = New D3D11_SAMPLER_DESC
		sd.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP
		sd.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP
		sd.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP
		sd.MipLODBias = 0.0
		sd.MaxAnisotropy = 1
		sd.ComparisonFunc = D3D11_COMPARISON_GREATER_EQUAL
		sd.BorderColor0 = 0.0
		sd.BorderColor1 = 0.0
		sd.BorderColor2 = 0.0
		sd.BorderColor3 = 0.0
		sd.MinLOD = 0.0
		sd.MaxLOD = D3D11_FLOAT32_MAX
		
		sd.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR
		If _d3ddev.CreateSamplerState(sd, _samplerLinear)<0
			WriteStdout "Cannot create linear sampler state~nExiting.~n"
		EndIf
		
		sd.Filter = D3D11_FILTER_MIN_MAG_MIP_POINT
		If _d3ddev.CreateSamplerState(sd, _samplerPoint)<0
			WriteStdout "Cannot create point sampler state~nExiting.~n"
		EndIf

		Return Self
	EndMethod
	
	Method Destroy()
		ReleaseNow()
	EndMethod
		
	Method CreateRenderImage:TRenderImage(width:Int, height:Int, UseImageFiltering:Int)
		Local renderimage:TD3D11RenderImage = New TD3D11RenderImage.CreateRenderImage(width, height)
		
		If UseImageFiltering
			renderimage.Init(_d3ddev, _d3ddevcon, _samplerLinear)
		Else
			renderimage.Init(_d3ddev, _d3ddevcon, _samplerPoint)
		EndIf
	
		_renderimages.AddLast(renderimage)

		Return renderimage
	EndMethod
	
	Method DestroyRenderImage(renderImage:TRenderImage)
		renderImage.DestroyRenderImage()
		_renderimages.Remove(renderImage)
	EndMethod
	
	Method CreatePixmapFromRenderImage:TPixmap(renderImage:TRenderImage)
		Return TD3D11RenderImage(renderImage).ToPixmap(_d3ddev)
	EndMethod
	
	Method GraphicsContext:TGraphics()
		Return _gc
	EndMethod

	Method SetRenderImage(renderimage:TRenderimage)
		If Not renderimage
			_d3ddevcon.RSSetViewports(1,_viewport)
			
			_d3ddevcon.OMSetRenderTargets(1, Varptr _backbuffer, Null)
			_d3ddevcon.VSSetConstantBuffers(0, 1, Varptr _matrixbuffer)
		Else
			renderimage.SetRenderImage()
		EndIf
	EndMethod
EndType
