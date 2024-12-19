<#
.SYNOPSIS 
    Editable variables available across all scripts
.PARAMETER tv_configId
    Allows Teamviwer custom installation
.PARAMETER tv_settings
    Teamviewer custom settings file that will be imported
.PARAMETER root
    Parent directory for all deployment files
.PARAMETER logs
    Directory in which logs will be saved
.PARAMETER adoroDomain
    Domain to join
.PARAMETER pulsServer
    Adoro's Puls server
.PARAMETER pulsLogin
    User for internal programs
.PARAMETER timeoutMonitor
    Time in minutes after which monitor goes to sleep
.PARAMETER activeHoursStart
    Time in hours - active hours start
.PARAMETER activeHoursEnd
    Time in hours - active hours end
.PARAMETER delay
    Time to wait until auto fill
.PARAMETER scripts
    Scripts that will be executed with system-second-boot
.PARAMETER software
    Object that contains programs which needs to be installed.
    Object properties:
        > name - short info
        > exe - correct and full name of installation file
        > type - system wide or user wide installation
        > args - arguments that installation accepts (see web). Type " " if empty
.PARAMETER regs
    Registries that CAN and are changed on startup with no administrator rights (visual changes).
    Object properties:
        > path - full path
        > name - string value
        > value - value corresponding to name
.PARAMETER paths
    Full paths to Adoro's internal programs on X:\
        > break - splits object to 2 parts: essential programs for every computer and optional programs below it
#>

                        <# | EDITABLE | #>
$tv_settings = "C:\ProgramData\Deployment\Other\settings.tvopt"
$global:root = "C:\ProgramData\Deployment"
$global:logs = "$($root)\Logs"
$data = Get-Content "$($root)\Startup\data.json" | ConvertFrom-Json 
$global:adoroDomain = $data.servers | Where-Object { $_.name -match "domain" } | Select-Object -ExpandProperty url
$global:pulsServer = $data.servers | Where-Object { $_.name -match "puls" } | Select-Object -ExpandProperty url
$global:pulsLogin = $data.users | Where-Object { $_.username -match "pogon" } 
$tv_configId = $data.other | Where-Object { $_.name -match "config" } | Select-Object -ExpandProperty info
$global:timeoutMonitor = $data.other | Where-Object { $_.name -match "timeout" } | Select-Object -ExpandProperty info 
$global:activeHoursStart = $data.other | Where-Object { $_.name -match "start" } | Select-Object -ExpandProperty info      
$global:activeHoursEnd = $data.other | Where-Object { $_.name -match "end" } | Select-Object -ExpandProperty info     
$global:scripts = @(    <# Scripts to run with system-second-boot.ps1 #>  
    "$($root)\Scripts\install.ps1"
    "$($root)\Startup\startup.ps1"
)
$global:software = @(   <# Basic programs to install #>
@{ name="7-Zip"; exe="7z2408-x64.exe"; type="Machine"; args="/S" },
@{ name="Google Chrome"; exe="googlechromestandaloneenterprise64.msi"; type="Machine"; args="/qn" },
@{ name="Sumatra PDF"; exe="SumatraPDF-3.5.2-64-install.exe"; type="Machine"; args="-s -all-users" },
@{ name="Crystal Disk Info"; exe="CrystalDiskInfo9_4_4.exe"; type="Machine"; args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" },
@{ name="Team Viewer Host"; exe="TeamViewer_Host.msi"; type="Machine"; args="/qn SETTINGSFILE=`"$($tv_settings)`" CUSTOMCONFIGID=$($tv_configId)" },
@{ name="OCS Agent"; exe="OCS-Windows-Agent-Setup-x64.exe"; type="Machine"; args="/S /SERVER=http://adoro-ocs.adoro-tueren.lan/ocsinventory" },
@{ name="Eset Antivirus (Adoro)"; exe="Adoro-ESET-PROTECT_Installer_x64 v11.0.2044.0_en_US.exe"; type="Machine"; args="--silent --accepteula" },
@{ name="Eset Antivirus (Brandor)"; exe="Brandor-ESET-PROTECT_Installer_x64 v11.0.2044.0_en_US.exe"; type="Machine"; args="--silent --accepteula" },
                        <# Framework programs, please keep .NET 3.5 on top! #>
@{ name="Dot NET 3.5"; exe=" "; type="Machine"; args=" " },
@{ name="Microsoft Interop Forms Redist"; exe="WFX_Microsoft.InteropFormsRedist.msi"; type="Machine"; args="/qn" },
@{ name="CrystalReports 2005 64 bit"; exe="WFX_CRRedist2005_X64.msi"; type="Machine"; args="/qn" },
@{ name="CrystalReports 2005 32 bit"; exe="WFX_CRRedist2005_x86.msi"; type="Machine"; args="/qn" },
@{ name="CrystalReports 2022 32 bit"; exe="WFX_CRRuntime_32bit_13_0_32.msi"; type="Machine"; args="/qn" },
@{ name="CrystalReports 2022 64 bit"; exe="WFX_CRRuntime_64bit_13_0_32.msi"; type="Machine"; args="/qn" },
                        <# Office programs - installation file (exe) must contain "Office" #>
@{ name="Office 2016 Pro (Macros disabled automatically)"; exe="Office.exe"; type="Machine"; args=" " },
@{ name="Office 2016 Home and Business (Must manually disable macros)"; exe="OfficeSetup.exe"; type="Machine"; args=" " },
@{ name="Libre Office"; exe="LibreOffice_7.3.7_Win_x64.msi"; type="Machine"; args="/qn /norestart" }
)
$global:regs = @(
@{ path = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"; name = "(Default)"; value = "" },
@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; name = "UseCompactMode"; value = 1 },
@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; name = "BingSearchEnabled"; value = 0 },
@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; name = "SearchboxTaskbarMode"; value = 1 },
@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; name = "ShowTaskViewButton"; value = 0 },
@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; name = "HideFileExt"; value = 0 }
)
$global:paths = @(      <# Essential puls programs - keep Andromeda first and ProPuls last #>
"\\maple.adoro-tueren.lan\it\instalacije\1-AAA - Instalacija novih racunala\1-AAA - PROGRAMI i podsjetnici za instalaciju\Andromeda - Kiteron\Andromeda_"
"X:\sw_puls_instalacije\PraProStolAny\PraProStol.application"
"X:\sw_puls_instalacije\PulsISTehno\PulsISTehno.application"
"X:\sw_puls_instalacije\PraProStolKT471\PraProStolKT.application"
"X:\sw_puls_instalacije\ProPuls\Disk1"
"break"
                        <# Optional puls programs #>
"X:\sw_puls_instalacije\PulsIS\PulsIS.application"
"X:\sw_puls_instalacije\PaleteGP\PaleteGP.application"
"X:\sw_puls_instalacije\ProPulsEmailPotvrde\ProPulsEmailPotvrda.application"
"X:\sw_puls_instalacije\KTIzomat\KTIzomat.application"
"X:\sw_puls_instalacije\PraProStolPlast\PraProStolPlast.application"
)                       <# ------------ #>

function Fix { 
    <#
    .SYNOPSIS
        Apply visual changes on current user
    .DESCRIPTION
        1. Modify registries based on $regs parameter
        2. Read "HKCU:\Software\Deployment\Unpinned" and "HKCU:\Software\Deployment\FixedStartMenu"
            - Unpinned: if "No", unpin everything from taskbar
            - FixedStartMenu: if "No", import custom start menu file
        3. "Lock" those registries by setting values to "Yes" so these changes do not occur again on current user
        4. Show all icons on taskbar
    .NOTES
        Author: fs
        Last edit: 20_11_2024 fs
        Version:
            1.0 - added basic functionality
            1.1 - added unpinning of edge and microsoft store
            1.2 - all icons are now shown on taskbar
            1.3 - turned this script that once was in Run registry into a function Fix
            1.4 - integrated with startup.ps1 script and removed from Run registry
            1.5 - added start menu customization based on start2.bin file
    #>

    $regs | ForEach-Object {
        if (-not (Test-path $_.path)) { 
            New-Item -path $_.path -Force | Out-Null 
        } else { 
            Set-ItemProperty -path $_.path -name $_.name -value $_.value -Type DWord -Force | Out-Null 
        }
    }

    $reg = "HKCU:\Software\Deployment"
    $value1 = Get-ItemProperty -path $reg -name "Unpinned" -ErrorAction SilentlyContinue 
    $value2 = Get-ItemProperty -path $reg -name "FixedStartMenu" -ErrorAction SilentlyContinue 

    if ($value1.Unpinned -eq "No") {
        if (Test-path -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband") {
            Remove-Item -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Force -Recurse -ErrorAction SilentlyContinue
            Set-ItemProperty -path $reg -name "Unpinned" -value "Yes" | Out-Null
        }
    }

    if ($value2.FixedStartMenu -eq "No") {
        if (Test-path -path "$($root)\Startup\start2.bin") {
            Copy-Item "$($root)\Startup\start2.bin" "$($env:LocalAppData)\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState" -Force
            Set-ItemProperty -path $reg -name "FixedStartMenu" -value "Yes" | Out-Null
        }
        $rc = @{ path = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"; name = "(Default)"; value = "" }
        if (-not (Test-path $rc.path)) { 
            New-Item -path $rc.path -Force | Out-Null 
        } else { 
            Set-ItemProperty -path $rc.path -name $rc.name -value $rc.value -Type DWord -Force | Out-Null 
        }
        Get-Process explorer | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path "HKCU:\Control Panel\NotifyIconSettings") {
        Get-ChildItem "HKCU:\Control Panel\NotifyIconSettings" | ForEach-Object { 
            Set-ItemProperty -path $_.PSpath -name 'IsPromoted' -Type 'DWORD' -value 1 
        }
    }

    Set-Culture -CultureInfo "hr-HR"
}

function Install {
    <#
    .SYNOPSIS
        Install a program from specific path
    .DESCRIPTION
        1. Protect/lock critical section with mutex object
        2. Define $execute object based on program's extension
        3. Install program with $execute object
        4. Check for errors and unlock the function for next process
    .PARAMETER program
        Custom object defined in install scripts
    .PARAMETER path
        Path which contains installation
    .NOTES
        Author: fs
        Last edit: 2_12_2024 fs
        Version:
            1.0 - added basic functionality
            1.1 - improved error handling 
            1.2 - improvements and bug fixes
    #>

    param (
        [Parameter(Mandatory=$true)] [PSCustomObject] $program,
        [Parameter(Mandatory=$true)] [string] $path 
    )

    try {
        $mutex = New-Object System.Threading.Mutex($false, "Global\InstallMutex")
        $mutex.WaitOne() | Out-Null
        if (Test-path $path) {
            Write-Output "$(Time) Installing $($program.name)..."
            if ($program.exe -like "*.msi") {
                $execute = @{
                    Filepath     = "msiexec"
                    ArgumentList = "/i `"$($path)\$($program.exe)`" $($program.args)"
                    NoNewWindow  = $true
                    PassThru     = $true
                    Wait         = $true
                }
            } else {
                $execute = @{
                    Filepath     = "$($path)\$($program.exe)"
                    ArgumentList = $program.args
                    NoNewWindow  = $true
                    PassThru     = $true
                    Wait         = $true
                }
            }
            try {
                $process = Start-Process @execute
                $process.WaitForExit()
                if ($process.ExitCode -eq 0) {
                    Write-Output "$(Time) Installation successful for $($path)\$($program.exe)." 
                } else {
                    Write-Output "$(Time) Installation failed for $($path)\$($program.exe), exit code: $($process.ExitCode)"
                }
            } catch {
                $err = $_.Exception.Message
                Write-Output "$(Time) An error occurred while installing $($path)\$($program.exe): $err"
            }
        } else { 
            Write-Output "$(Time) File $($path)\$($program.exe) not found." 
        }
    } finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}

function TypeInit {
    <#
    .SYNOPSIS
        Keyboard event declarations
    .NOTES
        Author: fs
        Last edit: 17_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);
        public const byte VK_LWIN = 0x5B;   
        public const byte VK_LEFT = 0x25;   
        public const byte VK_RETURN = 0x0D; 
        public const byte VK_UP = 0x26;
        public const uint KEYEVENTF_KEYDOWN = 0x0000; 
        public const uint KEYEVENTF_KEYUP = 0x0002; 
    }
"@
}

function SplitView {
    <#
    .SYNOPSIS
        Split PowerShell windows
    .NOTES
        Author: ap
        Last edit: 6_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    TypeInit
    [User32]::keybd_event([User32]::VK_LWIN, 0, [User32]::KEYEVENTF_KEYDOWN, 0)
    Start-Sleep -Milliseconds 300
    [User32]::keybd_event([User32]::VK_LEFT, 0, [User32]::KEYEVENTF_KEYDOWN, 0)
    Start-Sleep -Milliseconds 300
    [User32]::keybd_event([User32]::VK_LEFT, 0, [User32]::KEYEVENTF_KEYUP, 0)
    Start-Sleep -Milliseconds 300
    [User32]::keybd_event([User32]::VK_LWIN, 0, [User32]::KEYEVENTF_KEYUP, 0)
    Start-Sleep -Milliseconds 300
    [User32]::keybd_event([User32]::VK_RETURN, 0, [User32]::KEYEVENTF_KEYDOWN, 0)
    Start-Sleep -Milliseconds 300
    [User32]::keybd_event([User32]::VK_RETURN, 0, [User32]::KEYEVENTF_KEYUP, 0)
}

function MaximizeWindow {
    <#
    .SYNOPSIS
        Maximize PowerShell window
    .NOTES
        Author: fs
        Last edit: 17_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    TypeInit
    $wsh = New-Object -ComObject WScript.Shell
    do { $activated = $wsh.AppActivate('Startup') } while ($activated -eq $false)

    [User32]::keybd_event([User32]::VK_LWIN, 0, [User32]::KEYEVENTF_KEYDOWN, 0)
    Start-Sleep -Milliseconds 100
    [User32]::keybd_event([User32]::VK_UP, 0, [User32]::KEYEVENTF_KEYDOWN, 0)
    Start-Sleep -Milliseconds 100
    [User32]::keybd_event([User32]::VK_UP, 0, [User32]::KEYEVENTF_KEYUP, 0)
    Start-Sleep -Milliseconds 100
    [User32]::keybd_event([User32]::VK_LWIN, 0, [User32]::KEYEVENTF_KEYUP, 0)
    Start-Sleep -Milliseconds 100
}

function ProPulsInstall {
    <#
    .SYNOPSIS
        Auto-Install ProPuls program
    .NOTES
        Author: fs
        Last edit: 17_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    @'
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandpath`"" -Verb RunAs
        exit 
    } 
    . "C:\ProgramData\Deployment\Startup\config.ps1"

    TypeInit

    function Enter {
        [User32]::keybd_event([User32]::VK_RETURN, 0, [User32]::KEYEVENTF_KEYDOWN, 0)
        Start-Sleep -Milliseconds 500
        [User32]::keybd_event([User32]::VK_RETURN, 0, [User32]::KEYEVENTF_KEYUP, 0)
    }

    function Tab {
        [User32]::keybd_event(0x09, 0, [User32]::KEYEVENTF_KEYDOWN, 0)  
        Start-Sleep -Milliseconds 500
        [User32]::keybd_event(0x09, 0, [User32]::KEYEVENTF_KEYUP, 0)  
    }

    function TypeText {
        param([string]$text)
        $keys = @(
            @{ symbol = 'a'; code = 0x41 },
            @{ symbol = 'd'; code = 0x44 },
            @{ symbol = 'o'; code = 0x4F },
            @{ symbol = 'r'; code = 0x52 },
            @{ symbol = 'p'; code = 0x50 },
            @{ symbol = 'c'; code = 0x43 },
            @{ symbol = '0'; code = 0x30 },
            @{ symbol = '1'; code = 0x31 },
            @{ symbol = '2'; code = 0x32 },
            @{ symbol = '3'; code = 0x33 },
            @{ symbol = '4'; code = 0x34 },
            @{ symbol = '5'; code = 0x35 },
            @{ symbol = '6'; code = 0x36 },
            @{ symbol = '7'; code = 0x37 },
            @{ symbol = '8'; code = 0x38 },
            @{ symbol = '9'; code = 0x39 } )    
        foreach ($char in $text.ToCharArray()) {
            $key = $keys | Where-Object { $_.symbol -eq $char }
            [User32]::keybd_event($key.code, 0, [User32]::KEYEVENTF_KEYDOWN, 0)
            Start-Sleep -Milliseconds 100
            [User32]::keybd_event($key.code, 0, [User32]::KEYEVENTF_KEYUP, 0)
            Start-Sleep -Milliseconds 100
        }
    }

    Start-Process -FilePath "C:\ProPulsTemp\Disk1\Setup.exe" -ErrorAction SilentlyContinue 
    $wsh = New-Object -ComObject WScript.Shell
    do { $activated = $wsh.AppActivate('ProPuls Setup') } while ($activated -eq $false)
    Start-Sleep -s 1
    Enter
    Enter
    TypeText "$([System.Net.Dns]::GetHostName())"
    Tab
    TypeText "adoro"
    Tab
    Tab
    Enter
    Enter
    Enter
    Enter
    Start-Sleep -s 7
    Enter
    Enter
    Enter
    Enter
    Enter
    Enter
    Remove-Item -Path "C:\ProPulsTemp" -Recurse
'@ | Out-File -Filepath "$($env:TEMP)\run.ps1" -Encoding UTF8
    Start-Process -Filepath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($env:TEMP)\run.ps1`"" -Wait
}

function Cleanup {
    <#
    .SYNOPSIS
        Remove all deployment files
    .DESCRIPTION
        1. Create temp file called remove.ps1 and run it
        2. Remove files and remove itself
        3. Put "HKCU:\Software\Deployment\Clean" to Yes
    .NOTES
        Author: fs
        Last edit: 25_11_2024 fs
        Version:
            1.0 - added basic functionality
            1.1 - added UAC window pop-up
    #>

    @'
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandpath`"" -Verb RunAs
        exit 
    }
    $host.ui.RawUI.WindowTitle = "Cleanup"
    Get-ChildItem -path "C:\ProgramData\Deployment" -Directory | Where-Object { $_.name -notin @("Startup", "Logs", "Tools") } | ForEach-Object {
        Write-Host "Removing $($_.Fullname) and it's files from C:\ProgramData\Deployment ..."
        Remove-Item $_.Fullname -Recurse -Force 
        Start-Sleep -s 1
    }
    Set-ItemProperty -path "HKCU:\Software\Deployment" -name "Clean" -value "Yes" | Out-Null
    Remove-Item -path $MyInvocation.MyCommand.Source -ErrorAction SilentlyContinue 
'@ | Out-File -Filepath "$($env:TEMP)\remove.ps1" -Encoding UTF8
    Start-Process -Filepath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($env:TEMP)\remove.ps1`""
}

function AutoHotkeyFill {
    <#
    .SYNOPSIS
        Send hotkeys
    .NOTES
        Author: fs
        Last edit: 9_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    $wsh = New-Object -ComObject WScript.Shell
    do { $active = $wsh.AppActivate('Prijava korisnika') } while ($active -eq $false)
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys($pulsServer) 
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys($pulsLogin.username) 
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys($pulsLogin.password) 
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys("{ENTER}") 
    do { $active = $wsh.AppActivate('Izbor tvrtke i poslovne godine') } while ($active -eq $false)
    $wsh.SendKeys("{ENTER}") 
    Start-Sleep -s 1
    $wsh.SendKeys("%{F4}")
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys("{ENTER}") 
}

function AutoHotkeyAccept {
    <#
    .SYNOPSIS
        Send hotkeys
    .NOTES
        Author: fs
        Last edit: 6_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    $wsh = New-Object -ComObject WScript.Shell
    do { $active = $wsh.AppActivate('Application Install - Security Warning') } while ($active -eq $false)
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys("{TAB}") 
    $wsh.SendKeys("{ENTER}") 
}

function NewRegistry {
    <#
    .SYNOPSIS
        Creates new registry with default value provided
    .PARAMETER root
        path: root 
    .PARAMETER key
        path: root/key
    .PARAMETER item
        path: root/key/item
    .PARAMETER value
        path: root/key/item/value
    .NOTES
        Author: fs
        Last edit: 20_11_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    param (
        [Parameter(Mandatory=$true)] [string] $root,
        [Parameter(Mandatory=$true)] [string] $key,
        [Parameter(Mandatory=$true)] [string] $item,
        [Parameter(Mandatory=$true)] [string] $value
    )
    
    Set-Location $root
    $path = "$($root)\$($key)"
    if (-not (Test-path $path)) { Get-Item -path $root | New-Item -name $key -Force | Out-Null }
    New-ItemProperty -path $path -name $item -value $value -PropertyType String -Force | Out-Null
    Pop-Location
}

function GetActive {
    <#
    .SYNOPSIS
        Get active power plan
    .NOTES
        Author: fs
        Last edit: 5_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    $output = powercfg /list
    $msg = $output -split "`n"
    for ($i = 0; $i -lt $msg.Length; $i++) {
        if ($msg[$i] -match "guid" -and $msg[$i] -match '\*') {
            $index = $i
            break
        }
    }
    return $msg[$index]
}

function Prompt {
    <#
    .SYNOPSIS
        Prompt user and cancel empty inputs
    .PARAMETER text
        Message to display
    .NOTES
        Author: fs
        Last edit: 2_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    param( [string] $text )
    
    do { $response = Read-Host $text } while ([string]::IsNullOrWhiteSpace($response)) 

    return $response
}

function Print {
    <#
    .SYNOPSIS
        Writes output with time format
    .NOTES
        Author: fs
        Last edit: 6_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    param ( [string] $string )

    if ($string.StartsWith("`n")) {
        $new = $string.Split([Environment]::NewLine)
        Write-Host "`n$(Time) $($new[1])"
    } else {
        Write-Host "$(Time) $string"
    }
}

function Time {
    <#
    .SYNOPSIS
        Returns time in specific format
    .NOTES
        Author: fs
        Last edit: 6_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>
    return (Get-Date -Format '|dd.MM.yyyy, HH:mm:ss|')
}

function Timer {
    <#
    .SYNOPSIS
        Display message every $s seconds
    .PARAMETER s
        Determines how many seconds until some event
    .PARAMETER text
        Text to display 
    .PARAMETER text2
        Banner to display 
    .NOTES
        Author: fs
        Last edit: 20_11_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    param (
        [Parameter(Mandatory=$true)] [int] $s, 
        [Parameter(Mandatory=$true)] [string] $text,
        [string] $text2
    )

    for ($i = $s; $i -ge 1; $i--) {
        if ($text2) { DisplayBanner -text $text2 }
        Write-Host "$($text) $i s"
        Start-Sleep -s 1
        Clear-Host
    }
}

function DisplayOptions {
    <#
    .SYNOPSIS
        Display a list of options
    .PARAMETER list
        Any custom object that has name parameter defined
    .PARAMETER array
        Array of objects
    .NOTES
        Author: fs
        Last edit: 29_11_2024 fs
        Version:
            1.0 - added basic functionality
            1.1 - added new parameter $array
    #>

    param ( 
        [PSCustomObject] $list,
        [Array] $array
    )

    if ($null -ne $list) {
        for ($i = 0; $i -lt $list.count; $i++) { Write-Host "|$($i+1)| $($list[$i].name)" }
    } else {
        for ($i = 0; $i -lt $array.length; $i++) { 
            if (Split-Path $array[$i] -Leaf) {
                Write-Host "|$($i+1)| $(Split-Path -Path $array[$i] -Leaf)" 
            } else {
                Write-Host "|$($i+1)| $($array[$i])"
            } 
        }
    }
    Write-Host ""
}

function DisplayInstalledPrograms {
    <#
    .SYNOPSIS
        Displays a list of installed programs
    .NOTES
        Author: fs
        Last edit: 4_12_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    $accept = Prompt "`n$(Time) Do you want to see installed software? (y/n)"
    if ($accept -eq "y") { 
        Print "`nInstalled:"
        $installed = @()
        $installed += Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
        $installed += Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
        if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall") { $installed += Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate }
        $installed | Where-Object { $null -ne $_.DisplayName } | Sort-Object DisplayName | Format-Table -AutoSize
        Write-Host ""
    }

    Read-Host "$(Time) Press any key to exit..."
    exit
}

function DisplayBanner {
    <#
    .SYNOPSIS
        Displays message in special format
    .PARAMETER text
        Text that will be displayed
    .NOTES
        Author: fs
        Last edit: 20_11_2024 fs
        Version:
            1.0 - added basic functionality
    #>

    param ( [Parameter(Mandatory = $true)] [string] $text )

    $banner = 
"
________________________________________________________________________________
                            
                    $($text)
________________________________________________________________________________

"
    Write-Host "$($banner)"
}