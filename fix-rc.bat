@echo off
setlocal

powershell -ExecutionPolicy Bypass -Command ^
    "$reg = @{ path = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; name = '(Default)'; value = '' }; " ^
    "if (-not (Test-Path $reg.path)) { " ^
    "    New-Item -Path $reg.path -Force | Out-Null; " ^
    "} else { " ^
    "    Set-ItemProperty -Path $reg.path -Name $reg.name -Value $reg.value -Type DWord -Force | Out-Null; " ^
    "} " ^
    "Get-Process explorer | Stop-Process -Force -ErrorAction SilentlyContinue"

endlocal