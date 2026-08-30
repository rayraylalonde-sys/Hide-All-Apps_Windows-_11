[README.md](https://github.com/user-attachments/files/31614456/README.md)
# Hide All Apps — Windows 11 Start Menu

A PowerShell script that hides the "All Apps" list at the bottom of the Windows 11 Start Menu and replaces it with a custom **"All Programs"** launcher you can pin yourself.

## What it does

1. Sets the `NoStartMenuMorePrograms` registry policy (both `HKCU` and `HKLM`) to hide the built-in "All Apps" section
2. Creates an **All Programs** shortcut (`explorer.exe shell:AppsFolder`) with a custom icon
3. Copies it into your Start Menu Programs folder so Windows will let you pin it
4. Restarts Explorer to apply the change immediately

## Requirements

- Windows 11
- Administrator rights (the script relaunches itself elevated if needed)

## Usage

```powershell
# Apply the change
.\Hide-AllApps.ps1

# Undo it later (restores the default Start Menu)
.\Hide-AllApps.ps1 -Undo
```

If Windows blocks the script with an execution-policy error, run it via:

```powershell
powershell -ExecutionPolicy Bypass -File "Hide-AllApps.ps1"
```

or unblock the file first: right-click it → Properties → check **Unblock** → OK.

After running, open Start, search **"All Programs"**, right-click the result, and choose **Pin to Start**.

## Notes

- This changes a machine-wide policy key (`HKLM`), so it affects the Start Menu for all user accounts on the PC, not just the one running the script.
- Tested against Windows 11 Pro 25H2 (build 26200.9168).

## Disclaimer

This edits the Windows Registry. While the change is small and fully reversible via `-Undo`, back up your registry or create a system restore point first if you want extra peace of mind.
