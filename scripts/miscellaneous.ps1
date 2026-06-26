# Disable automatic start ServerManager
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# Remove link to GCloud SDK Shell
Remove-Item -Path 'C:\Users\Public\Desktop\Google Cloud SDK Shell.lnk' -Force

# Suppress the "Do you want to allow your PC to be discoverable..." network
# location prompt on first boot.
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff' -Force

# Classify the network as Private on every boot. Network classification happens
# after NLA identifies the link (post-boot), against a network GUID that does not
# exist at image-build time, so a registry pre-set can't cover it -- a startup
# task is the reliable mechanism. Domain-authenticated networks (the DC) are left
# untouched so they keep their Domain profile.
$helperDir = 'C:\ProgramData\Instruqt'
New-Item -Path $helperDir -ItemType Directory -Force | Out-Null
@'
$conn = $null
for ($i = 0; $i -lt 30 -and -not $conn; $i++) {
    Start-Sleep -Seconds 2
    $conn = Get-NetConnectionProfile -ErrorAction SilentlyContinue
}
Get-NetConnectionProfile |
    Where-Object { $_.NetworkCategory -ne 'DomainAuthenticated' } |
    Set-NetConnectionProfile -NetworkCategory Private
'@ | Set-Content -Path "$helperDir\set-network-private.ps1" -Encoding UTF8

$action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$helperDir\set-network-private.ps1`""
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName 'Set-Network-Private' -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
