# escape=`
ARG DLL_IMAGE


ARG BASETAG
FROM ghcr.io/epicgames/unreal-engine:runtime-windows-ltsc2022 AS full

# Gather the system DLLs that we need from the full Windows base image
RUN xcopy /y C:\Windows\System32\dsound.dll C:\GatheredDlls\ && `
	xcopy /y C:\Windows\System32\opengl32.dll C:\GatheredDlls\ && `
	xcopy /y C:\Windows\System32\glu32.dll C:\GatheredDlls\ && `
	xcopy /y C:\Windows\System32\MF.dll C:\GatheredDlls\ && `
	xcopy /y C:\Windows\System32\MFPlat.dll C:\GatheredDlls\ && `
	xcopy /y C:\Windows\System32\MFReadWrite.dll C:\GatheredDlls\ && `
	xcopy /y C:\Windows\System32\msdmo.dll C:\GatheredDlls\ && `
	xcopy /y C:\Windows\System32\dxva2.dll C:\GatheredDlls\







# Retrieve the DirectX runtime files required by the Unreal Engine,
# since even the full Windows base image does not include them
RUN curl  -L "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" --output %TEMP%\directx_redist.exe && `
	start /wait %TEMP%\directx_redist.exe /Q /T:%TEMP%\DirectX && `
	expand %TEMP%\DirectX\APR2007_xinput_x64.cab -F:xinput1_3.dll C:\GatheredDlls\ && `
	expand %TEMP%\DirectX\Jun2010_D3DCompiler_43_x64.cab -F:D3DCompiler_43.dll C:\GatheredDlls\ && `
	expand %TEMP%\DirectX\Feb2010_X3DAudio_x64.cab -F:X3DAudio1_7.dll C:\GatheredDlls\ && `
	expand %TEMP%\DirectX\Jun2010_XAudio_x64.cab -F:XAPOFX1_5.dll C:\GatheredDlls\ && `
	expand %TEMP%\DirectX\Jun2010_XAudio_x64.cab -F:XAudio2_7.dll C:\GatheredDlls\

# Retrieve the DirectX shader compiler files needed for DirectX Raytracing (DXR)
RUN curl   -L "https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.8.2407/dxc_2024_07_31.zip" --output %TEMP%\dxc.zip && `
	powershell -Command "Expand-Archive -Path \"$env:TEMP\dxc.zip\" -DestinationPath $env:TEMP" && `
	xcopy /y %TEMP%\bin\x64\dxcompiler.dll C:\GatheredDlls\ && `
	xcopy /y %TEMP%\bin\x64\dxil.dll C:\GatheredDlls\

# Copy the required DLLs from the full Windows base image into a smaller Windows Server Core base image
ARG BASETAG
FROM ghcr.io/epicgames/unreal-engine:runtime-windows-ltsc2022
COPY --from=full C:\GatheredDlls\ C:\Windows\System32\


COPY nvidiadlls\sys32\nvapi64.dll C:\Windows\System32\nvapi64.dll
COPY nvidiadlls\sys32\nvcuda.dll C:\Windows\System32\nvcuda.dll
COPY nvidiadlls\sys32\nvcudadebugger.dll C:\Windows\System32\nvcudadebugger.dll
COPY nvidiadlls\sys32\nvcuvid.dll C:\Windows\System32\nvcuvid.dll
COPY nvidiadlls\sys32\nvEncodeAPI64.dll C:\Windows\System32\nvEncodeAPI64.dll
COPY nvidiadlls\sys32\nvml.dll C:\Windows\System32\nvml.dll
COPY nvidiadlls\sys32\OpenCL.dll C:\Windows\System32\OpenCL.dll
COPY nvidiadlls\sys32\nvapi64.dll C:\Windows\System32\nvapi64.dll
COPY nvidiadlls\sys32\vulkan-1.dll C:\Windows\System32\vulkan-1.dll



COPY nvidiadlls\syswow64\nvapi.dll C:\Windows\SysWOW64\nvapi.dll
COPY nvidiadlls\syswow64\nvcuda.dll C:\Windows\SysWOW64\nvcuda.dll
COPY nvidiadlls\syswow64\nvcuvid.dll C:\Windows\SysWOW64\nvcuvid.dll
COPY nvidiadlls\syswow64\nvEncodeAPI.dll C:\Windows\SysWOW64\nvEncodeAPI.dll
COPY nvidiadlls\syswow64\OpenCL.dll C:\Windows\SysWOW64\OpenCL.dll
COPY nvidiadlls\syswow64\vulkan-1.dll C:\Windows\SysWOW64\vulkan-1.dll


COPY nvidiadlls\sys32\vulkaninfo.exe C:\Windows\System32\vulkaninfo.exe
COPY nvidiadlls\sys32\nvidia-smi.exe C:\Windows\System32\nvidia-smi.exe
COPY nvidiadlls\syswow64\vulkaninfo.exe C:\Windows\SysWOW64\vulkaninfo.exe





# Install the Visual C++ runtime files using Chocolatey
RUN powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
RUN choco install -y vcredist-all

# Copy the files from the build context to the hostdir path inside the container
#COPY nvidiadlls/ C:/hostdir/nvidiadlls/

# Use xcopy to copy the files to the target directory inside the container
#RUN xcopy /y /s /e C:/hostdir/nvidia/* C:/GatheredDlls/
