<#
.SYNOPSIS
    Allow user to select installation type and set the hostname 
.DESCRIPTION
    * Create control registries
    * Let user select Office packet and Eset
    * Prompt user for hostname until confirmation and rename computer
    * Create a scheduled task that will run after reboot and execute system-second-boot.ps1 script
    * Restart
.NOTES
    Author: fs
    Last edit: 17_12_2024 fs
    Version:
        1.0 - added basic functionality
        1.1 - added company selection
        1.2 - added default registries
        1.3 - added optional programs selection
        1.4 - added third option for non company devices
#>

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandpath`"" -Verb RunAs
    exit 
} 

$host.ui.RawUI.WindowTitle = "Select company and hostname"
. "C:\ProgramData\Deployment\Startup\config.ps1"

Start-Service w32time
Set-Service w32time -StartupType Automatic
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update
w32tm /resync

NewRegistry -root "HKLM:\Software" -key 'Deployment' -item "Company" -value "Not selected"
NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "InstallEset" -value "No"
NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "Office" -value "Not selected"
NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "Clean" -value "Hold"
NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "Unpinned" -value "No"
NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "FixedStartMenu" -value "No"
NewRegistry -root "HKCU:\Software" -key 'Deployment' -item "Finished" -value "No"

Clear-Host

$selected = $false
while ($selected -eq $false) {
    $company = Read-Host "$(Time) Type in the company first (1=Adoro | 2=Brandor | 3=None)"
    switch ($company) {
        "1" { Set-ItemProperty -Path "HKLM:\Software\Deployment" -Name "Company" -Value "Adoro"; $selected=$true }
        "2" { Set-ItemProperty -Path "HKLM:\Software\Deployment" -Name "Company" -Value "Brandor"; $selected=$true }
        "3" { Set-ItemProperty -Path "HKLM:\Software\Deployment" -Name "Company" -Value "None"; $selected=$true }
        default { Print "Wrong option, type 1,2 or 3 again.`n" }
    }
}

if ($company -ne 3) {
    $accept = Prompt "`n$(Time) Do you allow Eset (check licenses first) to install? (y/n)"
    if ($accept -eq "y") { 
        Set-ItemProperty -Path "HKCU:\Software\Deployment" -Name "InstallEset" -Value "Yes"
    }
}

DisplayBanner -text "Office select & install"
$programs = $software | Where-Object { $_.name -match "Office"}
DisplayOptions -list $programs

do {
    $pass = $false
    $selection = Read-Host "$(Time) Type in the number for the Office packet you wish to install. q = none above"
    if ($selection -eq "q") { 
        $index = 0
        $pass = $true 
    } else {
        $index = $selection -as [int]
        if($index -gt $programs.Length -or $index -lt 1){
            Print "Index out of range, try again.`n"
        } else { 
            $pass = $true 
        }
    }
} while ($pass -ne $true)

Set-ItemProperty -Path "HKCU:\Software\Deployment" -Name "Office" -Value $index
Write-Host ""

do {
    $name = Read-Host "$(Time) Enter the hostname (PC will restart after confirmation)"
    $confirm = Read-Host "$(Time) Confirm? (y/n)"
    Write-Host ""
} while ($confirm -ne "y")

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\Deployment\Scripts\system-second-boot.ps1"'
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "SecondBoot" -Description "Run system-second-boot.ps1 file" -User "admin" -RunLevel Highest

Clear-Host
Timer -s 5 -text "Computer will restart in"
Rename-Computer -NewName $name -Restart 