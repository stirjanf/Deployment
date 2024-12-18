<#
.SYNOPSIS
    Prepare system for deployment
.DESCRIPTION
    * Create local admin without password for auto-login
    * Remove bloatware
    * Create Deployment directory in ProgramData and sort files 
    * Create RunOnce registry that will execute system-first-boot.ps1 for first time login
    * Remove certain registries (OneDrive, Privacy Experience...)
.NOTES
    Author: fs
    Last edit: 29_11_2024 fs
    Version:
        1.0 - added basic functionality
        1.1 - fixed folder creation logic and file sorting
        1.2 - bug fixes
#>

function CreateFolder {
    param ( [string] $path )
    if (-not (Test-Path $path)) { 
        New-Item $path -ItemType Directory -Force | Out-Null 
        Print "$($path) directory sucessfully created."
    } else { 
        Print "$($path) directory already exists." 
    }
}

function Print {
    param ( [string] $string )
    if ($string.StartsWith("`n")) {
        $new = $string.Split([Environment]::NewLine)
        Write-Host "`n$(Time) $($new[1])"
    } else {
        Write-Host "$(Time) $string"
    }
}

Start-Service w32time
Set-Service w32time -StartupType Automatic
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update
w32tm /resync

New-LocalUser -Name "admin" -NoPassword
Set-LocalUser -Name "admin" -PasswordNeverExpires $true 
Add-LocalGroupMember -Group "Administrators" -Member "admin"

$apps = 
"Clipchamp.Clipchamp",
"Microsoft.WindowsAlarms",
"Microsoft.WindowsMaps",
"Microsoft.ZuneMusic",
"Microsoft.BingNews",
"Microsoft.Todos",
"Microsoft.ZuneVideo",
"Microsoft.ScreenSketch",
"Microsoft.MicrosoftSolitaireCollection",
"Microsoft.BingWeather",
"Microsoft.Xbox.TCUI",
"Microsoft.GamingApp",
"Microsoft.549981C3F5F10",
"Microsoft.WindowsFeedbackHub",
"microsoft.windowscommunicationsapps",
"Microsoft.MicrosoftOfficeHub",
"Microsoft.OutlookForWindows", 
"Microsoft.People",
"Microsoft.PowerAutomateDesktop",
"MicrosoftCorporationII.QuickAssist",
"Microsoft.WindowsSoundRecorder",
"Microsoft.MicrosoftStickyNotes",
"Microsoft.Windows.Ai.Copilot.Provider",
"*Teams*",
"*Copilot*"

foreach ($app in $apps){
    Get-AppxPackage | Where-Object {$_.PackageFullName -like $app} | Remove-AppxPackage -AllUser
    Get-AppxProvisionedPackage -Online | Where-Object{$_.DisplayName -like $app} | Remove-AppxProvisionedPackage -Online -AllUser
}

$root = "C:\ProgramData\Deployment"
CreateFolder -path $root

@("Logs", "Scripts", "Software", "Other", "Startup", "Tools" ) | ForEach-Object {
    CreateFolder -path "$($root)\$_"
}

$log = "$($root)\Logs\system-setup.log"
Start-Transcript -Path $log -Append | Out-Null

Get-ChildItem | Where-Object {$_.Name -ne "system-setup.ps1"} | ForEach-Object{
    if ($_.Name -like "startup*" -or $_.Name -like "config*" -or $_.Name -like "start2*" -or $_.Name -like "data*") {
        Copy-Item $_.FullName "$($root)\Startup\$($_.Name)" -Force
    } elseif ($_.name -match "tool") {
        Copy-Item $_.FullName "$($root)\Tools\$($_.Name)" -Force
    } elseif ($_.Extension -eq ".ps1") {
        Copy-Item $_.FullName "$($root)\Scripts\$($_.Name)" -Force
    } elseif ($_.Extension -eq ".txt" -or $_.Extension -eq ".tvopt") {
        Copy-Item $_.FullName "$($root)\Other\$($_.Name)" -Force
    } else {
        Copy-Item $_.FullName "$($root)\Software\$($_.Name)" -Force
    }
    Print "The file $($_.Name) was moved and sorted to C:\ProgramData\Deployment directory."
}

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "FirstBoot" -Value ("cmd /c powershell.exe -ExecutionPolicy Bypass -File {0}\Scripts\system-first-boot.ps1" -f $root)
Print "Boot script has been set."
New-Item "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\DisableOneDrive" | New-ItemProperty -Name "StubPath" -Value 'REG DELETE "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f'
Print "Disabled OneDrive."
New-Item "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\HideCopilot" | New-ItemProperty -Name "StubPath" -Value 'REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f'
Print "Disabled Copilot.`n"

@( "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate", "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate" ) | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item $_ -Force
        Print "`nSuccessfully removed: $_"
    } else { 
        Print "`nPath not found: $_" 
    }
}

$settings = 
    [PSCustomObject]@{
        Path  = "SOFTWARE\Policies\Microsoft\Dsh"
        Value = 0
        Name  = "AllowNewsAndInterests"
    },
    [PSCustomObject]@{
        Path  = "SOFTWARE\Policies\Microsoft\Windows\OOBE"
        Value = 1
        Name  = "DisablePrivacyExperience"
    } | Group-Object Path

foreach ($setting in $settings) {
    $registry = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($setting.Name, $true)
    if ($null -eq $registry) { $registry = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($setting.Name, $true) }
    $setting.Group | ForEach-Object { if (!$_.Type) { $registry.SetValue($_.name, $_.value) } else { $registry.SetValue($_.name, $_.value, $_.type) } }
    $registry.Dispose()
}

Print "`nNews and interest removed from taskbar.`nPrivacy experience will no longer show on new users.`n"
Print "`nDeployed with: deployment-$([System.Environment]::MachineName)`n"

Stop-Transcript | Out-Null