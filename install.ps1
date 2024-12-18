<#
.SYNOPSIS
    Install programs provided in config.ps1
.NOTES
    Author: fs
    Last edit: 5_12_2024 fs
    Version:
        1.0 - added basic functionality
        1.1 - replaced installation logic with Install function
        1.2 - jobs now have timeout of 5 minutes (no outputs)
        1.3 - removed timeout and improved jobs logic to output errors and messages
        1.4 - merged all install scripts together
        1.5 - improvements and bug fixes
#>

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandpath`"" -Verb RunAs
    exit 
}

$host.ui.RawUI.WindowTitle = "Software installations"
. "C:\ProgramData\Deployment\Startup\config.ps1"

$programs = $software

$value = Get-ItemProperty -Path "HKLM:\Software\Deployment" -name "Company" -ErrorAction SilentlyContinue
if ($value.Company -eq "Adoro") { $programs = $programs | Where-Object { $_.exe -notmatch "Brandor" } } 
else { $programs = $programs | Where-Object { $_.exe -notmatch "Adoro" } }

$value = Get-ItemProperty -Path "HKCU:\Software\Deployment" -name "InstallEset" -ErrorAction SilentlyContinue
if ($value.InstallEset -eq "No") {
    $programs = $programs | Where-Object { $_.name -notmatch "eset" }
}

$value = Get-ItemProperty -Path "HKCU:\Software\Deployment" -name "Office" -ErrorAction SilentlyContinue
$index = $value.Office -as [int]
$office = $programs | Where-Object { $_.name -match "office" }

$log = "$($logs)\install-software.log"
Start-Transcript -Path $log -Append | Out-Null

DisplayBanner -text "Software installations script"

$programs | ForEach-Object {
    Print "`nStarting $($_.name) installation ..."
    if ($_.name -match "dot net") {
        Print "Please, DO NOT exit .NET installation or other installations won't be able to continue! It can take up to 15 minutes. `n"
        DISM /Online /Enable-Feature /Featurename:NetFx3 /All
        Write-Host ""
    } elseif ($_.name -match "office") {
        if ($index -ne 0) {
            $file = $office[$index-1]
            if ($_.name -eq "$($file.name)") {
                if ($file.name -match "pro") {
                    $tmp = "$env:TEMP\Office.exe"
                    Copy-Item -Path "$($root)\Software\$($file.exe)" -Destination $tmp -Force
                    Start-Process -FilePath $tmp -NoNewWindow -Wait
                    Write-Output "$(Time) Installation successful for $($path)\$($file.name)."
                } else {
                    Install -program $file -path "$($root)\Software"
                }
            }
        }
    } else {
        if (Test-Path "$($root)\Software\$($_.exe)") {
            Install -program $_ -path "$($root)\Software"
        }
    }
}

Print "`nInstallations finished. If any errors occured check log file at $($log)`n"
Set-ItemProperty -Path "HKCU:\Software\Deployment" -Name "Finished" -Value "Yes"

DisplayInstalledPrograms

Stop-Transcript | Out-Null