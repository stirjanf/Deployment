<#
.SYNOPSIS
    Perform certain actions on every startup for every user
.DESCRIPTION
    * Read "HKLM:\Software\Deployment\Company" for correct Andromeda installation
    * Create default registries if not present
    * Perform deployment files cleanup but only on local admin
    * Perform UI changes with Fix function on all users
    * Begin Puls installations only if user is domain user but not domain admin
    * Prompt user for additional installations
.NOTES
    Author: fs
    Last edit: 17_12_2024 fs
    Version:
        1.0 - added basic functionality
        1.1 - added selectable options
        1.2 - integrated Fix function into this script
        1.3 - improved overall script logic
        1.4 - improved performance and bugs
        1.5 - rewrote and improved overall logic
        1.6 - ProPuls is now asking to install only once
        1.7 - bug fixes + dynamic improvements + some variables are now moved to config.ps1 for easier access
        1.8 - added auto hotkeys and information fills + bug fixes
        1.9 - auto fill improvements
        1.10 - bug fixes + improvements
#>

function TryAgain {
    $accept = Prompt "$(Time) Do you want to try again next time? (y/n)"
    if ($accept -eq "y") {
        Set-ItemProperty -Path "HKCU:\Software\Deployment" -Name "PulsInstalled" -Value "Ready" | Out-Null
    }
}

$host.ui.RawUI.WindowTitle = "Startup"
. "C:\ProgramData\Deployment\Startup\config.ps1"

if (Test-Path "HKLM:\Software\Deployment") { 
    $val = Get-ItemProperty -Path "HKLM:\Software\Deployment" -Name "Company" -ErrorAction SilentlyContinue 
    $company = $val.Company
}

$files = $paths[0..($paths.IndexOf("break")-1)]
$files2 = $paths[($paths.IndexOf("break") + 1)..($paths.Length-1)]

$reg = "HKCU:\Software\Deployment"
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
TimeUpdate

if (-not (Test-Path $reg)) {
    NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "Unpinned" -value "No"
    NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "FixedStartMenu" -value "No"
    NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "PulsInstalled" -value "No"
    NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "Andromeda_$($company)" -value "No"
    foreach ($file in $files) { if ($file -notmatch "andromeda" -and $file -notmatch "propuls") { NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "$(Split-Path -Path $file -Leaf)" -value "No" } } 
    foreach ($file in $files2) { NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "$(Split-Path -Path $file -Leaf)" -value "No" }
}

if ("$($user)" -notmatch "adoro|brandor") {
    Fix 
    if ($user -like "*admin") { 
        $value = Get-ItemProperty -Path $reg -Name "Clean" -ErrorAction SilentlyContinue 
        if ($value.Clean -eq "Yes") {
            Print "All deployment files already deleted."
        } elseif ($value.Clean -eq "Ready") { 
            Clear-Host
            $accept = Prompt "$(Time) Do you agree to remove deployment files now? (y/n)"
            if ($accept -eq "y") { Cleanup }
        } else {
            Set-ItemProperty -Path "HKCU:\Software\Deployment" -Name "Clean" -Value "Ready" | Out-Null 
            Print "Cleanup process is now allowed and will begin on next sign out/sign in or boot."     
        }
    }
    exit
}

if ("$($user)" -match "admin.") {
    Fix
    exit
} else {
    $value = Get-ItemProperty -Path $reg -Name "PulsInstalled" -ErrorAction SilentlyContinue 
    if ($value.PulsInstalled -eq "Yes") { 
        Print "Puls software is already installed" 
        Fix
        exit
    }
    if ($value.PulsInstalled -eq "No") {
        Fix
        Set-ItemProperty -Path $reg -Name "PulsInstalled" -Value "Ready" | Out-Null
        Clear-Host
        $prompt = Prompt "$(Time) Windows needs to log you out in order to begin Puls installations.`nDo you agree to do it now? (y/n)"
        if ($prompt -eq "y") { shutdown.exe /l /f } 
        exit
    }
}

DisplayBanner "Puls software auto-installations"
MaximizeWindow

foreach ($file in $files) {
    Print "Starting $file installation..."
    try {
        if ($file -like "*Andromeda*") { $file += "$($company)" }
        if (Test-Path $file -ErrorAction Stop) {
            if ($file -like "*Andromeda*") {
                $filename = "Andromeda_$($company)"
                $installed = Get-ItemProperty -Path $reg -Name $filename -ErrorAction SilentlyContinue 
                if ($installed.$filename -eq "No") {
                    Print "Copying Andromeda files. Please wait..."
                    $andromeda = "C:\Andromeda_$($company)"
                    if (-not (Test-Path $andromeda)) { Copy-Item -Path $file -Destination $andromeda -Recurse }
                    Set-Location -Path $andromeda
                    Start-Process -FilePath "$($andromeda)\Andromeda.exe" -ErrorAction SilentlyContinue 
                    $wsh = New-Object -ComObject WScript.Shell
                    $shortcut = $wsh.CreateShortcut("$([System.Environment]::GetFolderPath('Desktop'))\Andromeda.lnk")
                    $shortcut.TargetPath = "$($andromeda)\Andromeda.exe"
                    $shortcut.WorkingDirectory = $andromeda
                    $shortcut.IconLocation = "$env:SystemRoot\System32\SHELL32.dll,80"
                    $shortcut.Save()
                    NewRegistry -root "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall" -key 'Andromeda' -item "DisplayName" -value "Andromeda $($company)"
                    Pop-Location
                    Print "Done."
                    Print "Waiting for Andromeda to update and login window to pop up..."
                    $wsh = New-Object -ComObject WScript.Shell
                    do { $activated = $wsh.AppActivate('Prijava') } while ($activated -eq $false)
                    Start-Sleep -s 1
                    $wsh.SendKeys("%{F4}")
                    Set-ItemProperty -Path $reg -Name $filename -Value "Yes" | Out-Null
                    Start-Sleep -s 4
                } else { 
                    Print "$filename already installed..." 
                }
            } elseif ($file -match "ProPuls"){
                if (-not (Test-Path "C:\ProPuls")) {
                    Copy-Item -Path $file -Destination "C:\ProPulsTemp" -Recurse
                    ProPulsInstall
                    Print "Done."
                    Start-Sleep -s 4
                } else {
                    Print "$file already installed..."
                }
            } else { 
                $filename = Split-Path -Path $file -Leaf
                $installed = Get-ItemProperty -Path $reg -Name $filename -ErrorAction SilentlyContinue 
                if ($installed.$filename -eq "No") {
                    Start-Process -FilePath $file -ErrorAction SilentlyContinue
                    Print "Waiting for $filename to finish installing..."
                    AutoHotkeyAccept
                    AutoHotkeyFill
                    Set-ItemProperty -Path $reg -Name $filename -Value "Yes" | Out-Null
                    Print "Done."
                    Start-Sleep -s 4
                } else {
                    Print "$file already installed..."
                }
            }
        } else { 
            Print "File not found: $($file)." 
        }
    } catch {
        if ($_.Exception -like "*denied*") {
            Print "Access is denied: this user does not have permissions to use $file.`nTry again by adding permissions and signing out/signing in."
            TryAgain
        } else {
            Print "Error: $_"
            TryAgain
        }
    }
    Write-Host ""
}

Set-ItemProperty -Path $reg -Name "PulsInstalled" -Value "Yes" | Out-Null

$list = New-Object System.Collections.ArrayList
$files2 | ForEach-Object { $list.Add("$(Split-Path -Path $_ -Leaf)") > $null }

DisplayBanner "Puls software select & install"
DisplayOptions -array $list

do {
    $prompt = Read-Host "$(Time) Type in the numbers separated by comma (e.g. 1,3) for software you wish to install (q = quit)" 
    if ($prompt -eq "q" ) { DisplayInstalledPrograms }
    $indices = $prompt.Split(',') | ForEach-Object { $_.Trim() }
    $valid = $true
    foreach ($index in $indices) {
        if ($index -match '^\d+$') {
            $index = [int]$index
            if ($index -lt 1 -or $index -gt $files2.Length) { $valid = $false }
        } else { $valid = $false }
    }
    if (-not $valid) { Print "1 or more invalid selections, please try again.`n" }
} while (-not $valid)

Write-Host ""

foreach ($index in $indices) { 
    $file = $files2[$index-1]
    $directory = $file -replace '\\[^\\]+$', ''
    Print "Starting $file installation..."
    try {
        Set-Location -Path $directory
        if(Test-Path $file) {
            $filename = Split-Path -Path $file -Leaf
            $installed = Get-ItemProperty -Path $reg -Name $filename -ErrorAction SilentlyContinue 
            if ($installed.$filename -eq "No") {
                Start-Process -FilePath $file -ErrorAction SilentlyContinue
                Print "Waiting for $filename to finish installing..."
                AutoHotkeyAccept
                if ($file -notmatch "email" -and $filename -notmatch "paletegp") { AutoHotkeyFill }
                if ($file -match "paletegp") {
                    $wsh = New-Object -ComObject WScript.Shell
                    do { $activated = $wsh.AppActivate('Lokacije - gotovi proizvodi i krila') } while ($activated -eq $false)
                    $wsh.SendKeys("%{F4}")
                    Start-Sleep -s 2
                    $wsh.SendKeys("{TAB}") 
                    $wsh.SendKeys("{ENTER}") 
                }
                Print "Done."
                Set-ItemProperty -Path $reg -Name $filename -Value "Yes" | Out-Null
                Start-Sleep -s 4
            } else {
                Print "$file already installed..."
            }
        } else { 
            Print "File not found: $($file)." 
        }
        Pop-Location
    } catch {
        if ($_.Exception -like "*denied*") {
            Print "Access is denied: this user does not have permissions to use $file.`nTry again by adding permissions and signing out/signing in."
            TryAgain
        } else {
            Print "Error: $_"
            TryAgain
        }
    }
    Start-Sleep -s 4
    Write-Host ""
}

DisplayInstalledPrograms