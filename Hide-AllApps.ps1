<#
.SYNOPSIS
    Hides the "All Apps" list at the bottom of the Windows 11 Start Menu and
    creates a custom "All Programs" launcher shortcut you can pin instead.

.DESCRIPTION
    Automates the 3 manual steps from the "Hide All Apps" guide:
      1. Sets the NoStartMenuMorePrograms registry policy (HKCU + HKLM)
      2. Creates an "All Programs" shortcut -> explorer.exe shell:AppsFolder
      3. Copies that shortcut into your Start Menu Programs folder so
         Windows will let you pin it
      4. Restarts Explorer so the change takes effect immediately

.USAGE
    Run normally to apply the change:
        .\Hide-AllApps.ps1

    Run with -Undo to reverse it (restores the default Start Menu):
        .\Hide-AllApps.ps1 -Undo

.NOTES
    - Must run elevated (Administrator) because it writes to HKEY_LOCAL_MACHINE
      and restarts Explorer. The script will relaunch itself elevated if needed.
    - After running, open Start, search "All Programs", right-click the result,
      and choose "Pin to Start."
    - Tested against the steps documented for Windows 11 Pro 25H2 (26200.9168).
#>

[CmdletBinding()]
param(
    [switch]$Undo
)

# --- Relaunch elevated if not already Administrator -------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Administrator rights required. Relaunching elevated..."
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Undo) { $argList += " -Undo" }
    Start-Process powershell -Verb RunAs -ArgumentList $argList
    exit
}

$regPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
)

function Restart-Explorer {
    Write-Host "Restarting Explorer to apply changes..." -ForegroundColor Cyan
    Stop-Process -Name explorer -Force
    Start-Sleep -Seconds 2
    Start-Process explorer.exe
}

# --- Undo path ---------------------------------------------------------------
if ($Undo) {
    Write-Host "Restoring the default Start Menu 'All Apps' list..." -ForegroundColor Cyan
    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name "NoStartMenuMorePrograms" -ErrorAction SilentlyContinue
        }
    }

    $startMenuPrograms = [Environment]::GetFolderPath("Programs")
    $pinnedShortcut = Join-Path $startMenuPrograms "All Programs.lnk"
    if (Test-Path $pinnedShortcut) { Remove-Item $pinnedShortcut -Force }

    Restart-Explorer
    Write-Host "Done. The default 'All Apps' list should be back." -ForegroundColor Green
    return
}

# --- Part 1: Registry policy tweak -------------------------------------------
Write-Host "Applying registry policy to hide the 'All Apps' list..." -ForegroundColor Cyan
foreach ($path in $regPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    New-ItemProperty -Path $path -Name "NoStartMenuMorePrograms" -PropertyType DWord -Value 1 -Force | Out-Null
}

# --- Part 2: Create the "All Programs" shortcut ------------------------------
Write-Host "Creating the 'All Programs' shortcut..." -ForegroundColor Cyan
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "All Programs.lnk"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "explorer.exe"
$shortcut.Arguments = "shell:AppsFolder"
# Icon index 197 in imageres.dll is a grid-style icon; change the number
# to pick a different one, or open Properties > Change Icon... later.
$shortcut.IconLocation = "imageres.dll,197"
$shortcut.Description = "Opens a list of all installed apps"
$shortcut.Save()

# --- Part 3: Copy into the Start Menu Programs folder ------------------------
Write-Host "Placing shortcut where Start Menu can pin it..." -ForegroundColor Cyan
$startMenuPrograms = [Environment]::GetFolderPath("Programs")
Copy-Item -Path $shortcutPath -Destination $startMenuPrograms -Force

Restart-Explorer

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "Open Start, search 'All Programs', right-click the result, and choose 'Pin to Start.'"
Write-Host "To reverse everything later, run:  .\Hide-AllApps.ps1 -Undo"
