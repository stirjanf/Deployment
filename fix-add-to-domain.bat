@echo off
setlocal

NET SESSION >nul 2>&1
if %errorlevel% == 0 (
    echo Script is running as Administrator.
) else (
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c', '%~f0' -Verb RunAs"
    exit /b
)

powershell -ExecutionPolicy Bypass -Command ^
    "$domain = 'adoro-tueren.lan'; " ^
    "do { " ^
    "    $err = $false; " ^
    "    ping '192.168.21.1'; " ^
    "    ipconfig /flushdns; " ^
    "    ping '192.168.21.1'; " ^
    "    try { " ^
    "        Add-Computer -DomainName $domain; " ^
    "    } catch { " ^
    "        Write-Host 'An error occurred:`n'; " ^
    "        $err = $true; " ^
    "    } " ^
    "} while ($err); " ^
    "$accept = Read-Host 'Restart computer now? (y/n)'; " ^
    "if ($accept -eq 'y') { Restart-Computer -Force }; " ^
    "exit"

endlocal