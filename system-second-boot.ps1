<#
.SYNOPSIS
    Run scripts on second startup and perform system changes
.DESCRIPTION
    1. Check for internet connection and block rest of the code until it's established
    2. Change local admin password
    3. Start execution of every script in Scripts folder except those defined in Where-Object line
    4. Add startup.ps1 script to Run registry so it executes on every logon
    5. Delete a Task that called it 
    6. Import default associations file
    7. Set high performance plan
    8. Set monitor sleep
    9. Set active hours
    10. Enable file removal by setting "HKCU:\Software\Deployment\Clean" to Yes
    11. Download Croatian language to the current user
    12. Set the display language to English
    13. Set the regional format to Croatian
    14. Set the input language to Croatian
    15. Set the location to Croatia
    16. Set timezone to Central European
    17. Copy those settings to all users on computer
    18. Ask to join domain
    19. Restart computer
.NOTES
    Author: fs
    Last edit: 4_12_2024 fs
    Version:
        1.0 - added basic functionality
        1.1 - added password change for admin user
        1.2 - added script filtering
        1.3 - added task removal and associations import
        1.4 - merged system.ps1 script with this one
        1.5 - merged language.ps1 script with this one
        1.6 - bug fixes
#>

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandpath`"" -Verb RunAs
    exit 
} 

$host.ui.RawUI.WindowTitle = "System modifications"
. "C:\ProgramData\Deployment\Startup\config.ps1"

$ProgressPreference_bk = $ProgressPreference
do {
    $ProgressPreference = "SilentlyContinue"
    $ping = Test-NetConnection '8.8.8.8' -InformationLevel Quiet
    if (!$ping) {
        Clear-Host
        'Waiting for internet connection. Make sure computer is connected via LAN or WLAN... (2s delay between checks)' | Out-Host
        Start-Sleep -s 2
    }
} while (!$ping)
$ProgressPreference = $ProgressPreference_bk

Print "`nInternet connection established!"
Clear-Host

$log = "$($logs)\system-second-boot.log"
Start-Transcript -Path $log -Append | Out-Null

DisplayBanner -text "System settings modify script"

$scripts | Where-Object { $_ -notmatch "startup" } | ForEach-Object {
    Print "Executing $_ script..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$_`""
}

Start-Sleep -s 2
SplitView

if (Get-ScheduledTask | Where-Object { $_.TaskName -eq "SecondBoot" }) {
    Unregister-ScheduledTask -TaskName "SecondBoot" -Confirm:$false
    Print "`nThis script will no longer run at boot."
}

if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\Startup")) {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Startup" -Value ("cmd /c powershell.exe -NoProfile -ExecutionPolicy Bypass -File {0}\Startup\startup.ps1" -f $root) | Out-Null
    Print "`nAdded startup.ps1 to HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run registry"
}

try {
    $msg = GetActive
    Print "`n$($msg) plan is currently active. Making changes..."
    powercfg -setactive SCHEME_MIN
    $msg = GetActive
    Print "`n$($msg) plan is now active."
    powercfg /list
    Write-Host ""
} catch {
    Print "An error occurred: $($_.Exception.Message)"
}

powercfg /change monitor-timeout-ac $timeoutMonitor
powercfg /change monitor-timeout-dc $timeoutMonitor
Print "Monitor sleep set for: $($timeoutMonitor/60) hours."

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursStart" -Value $activeHoursStart -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursEnd" -Value $activeHoursEnd -PropertyType DWord -Force | Out-Null
Print "`nActive hours set to: $($activeHoursStart)-$($activeHoursEnd)h"

$path = "$($root)\Other\apwd.txt"
if (Test-path $path) {
    $password = Get-Content $path -Raw | ConvertTo-SecureString -AsPlainText -Force
    Set-LocalUser -name "admin" -Password $password
    Remove-Item $path -Force
    Print "`nAdmin password changed successfuly."
} else { 
    Print "`nPassword file: $($path) does not exist." 
}

Print "`nDownloading Croatian language pack..."

$ProgressPreference_bk = $ProgressPreference
$ProgressPreference = "SilentlyContinue"
Install-Language -Language hr-HR
$ProgressPreference = $ProgressPreference_bk

$list = New-WinUserLanguageList -Language en-GB
$list.Add("hr-HR")
Set-WinUserLanguageList $list -Force
Print "Display language set to: English"

Set-WinHomeLocation -GeoID 108
Print "Regional format set to: Croatia"

Set-WinDefaultInputMethodOverride "041A:0000041A"
Print "Input language set to: Croatia"

Set-Culture -CultureInfo "hr-HR"
Print "Location set to: Croatia"

Set-TimeZone -Name "Central European Standard Time"
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update
w32tm /resync

Print "Timezone set to: Central European Standard Time"

Set-Culture -CultureInfo "hr-HR"
Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
Print "Copied language settings across the system.`n"

Stop-Transcript | Out-Null

do {
    $err = $false
    $accept = Prompt "$(Time) Do you want to join domain now? (y/n)"
    if ($accept -eq "y") {
        ping "192.168.21.1"
        ipconfig /flushdns
        ping "192.168.21.1"
        if ((Get-ItemProperty -Path "HKLM:\Software\Deployment" -Name "Company" -ErrorAction SilentlyContinue) -eq "Adoro") {
            try {
                Add-Computer -DomainName $adoroDomain 
            } catch {
                Print "An error occured: $($_.Exception.Message)`n"
                $err = $true
            }
        } else {
            # Add-Computer -DomainName $brandorDomain (in future, uncomment this line and delete line below)
            try {
                Add-Computer -DomainName $adoroDomain 
            } catch {
                Print "An error occured: $($_.Exception.Message)`n"
                $err = $true
            }
        }
    } 
} while ($err)

Print "Executing $($root)\Startup\startup.ps1..."
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($root)\Startup\startup.ps1`""

$accept = Prompt "`n$(Time) Do you want to restart your computer now? (y/n)" 
if ($accept -eq 'y') { Restart-Computer -Force }