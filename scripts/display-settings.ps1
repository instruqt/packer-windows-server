# Apply default display settings so new users inherit them:
#   1. Performance -> "Adjust for best appearance" (enables all visual effects)
#   2. Display -> Advanced -> "Let Windows try to fix apps so they're not blurry"
#
# Edits C:\Users\Default\NTUSER.DAT so new users inherit these settings.
# Runs as SYSTEM/admin at image-build time, before any interactive user exists.

$ErrorActionPreference = 'Stop'

& REG LOAD HKLM\DEFAULT C:\Users\Default\NTUSER.DAT
if ($LASTEXITCODE -ne 0) { throw "REG LOAD failed ($LASTEXITCODE)" }

try {
    # "Let Windows try to fix apps so they're not blurry"
    & REG ADD "HKLM\DEFAULT\Control Panel\Desktop" /v EnablePerProcessSystemDPI /t REG_DWORD /d 1 /f
    if ($LASTEXITCODE -ne 0) { throw "REG ADD EnablePerProcessSystemDPI failed ($LASTEXITCODE)" }

    # Bitmask of individual visual effects toggled on by "best appearance"
    & REG ADD "HKLM\DEFAULT\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9e2c078012000000 /f
    if ($LASTEXITCODE -ne 0) { throw "REG ADD UserPreferencesMask failed ($LASTEXITCODE)" }

    # Performance Options: 1 = "Adjust for best appearance"
    & REG ADD "HKLM\DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 1 /f
    if ($LASTEXITCODE -ne 0) { throw "REG ADD VisualFXSetting failed ($LASTEXITCODE)" }
}
finally {
    # Always attempt unload, even if a write failed, so the hive isn't left locked.
    [gc]::Collect(); [gc]::WaitForPendingFinalizers()
    & REG UNLOAD HKLM\DEFAULT
    if ($LASTEXITCODE -ne 0) {
        # Retry once - stray handles are the usual cause
        Start-Sleep -Seconds 2
        [gc]::Collect(); [gc]::WaitForPendingFinalizers()
        & REG UNLOAD HKLM\DEFAULT
        if ($LASTEXITCODE -ne 0) { throw "REG UNLOAD failed ($LASTEXITCODE) - changes may not persist" }
    }
}

Write-Output "Display settings applied successfully!"
