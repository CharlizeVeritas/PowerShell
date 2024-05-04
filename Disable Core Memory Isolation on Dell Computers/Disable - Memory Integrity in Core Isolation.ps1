# Define Variables
$dellBiosFile = "Disable VtForDirectIo_x64.exe"

# Clear Errors for Multiple Passes
$error.Clear()

# Get Current Location
$location = (Get-Location).Path

# Find Mount Point for Bitlocker
$mountPoint = (Get-BitLockerVolume | Where {$_.VolumeType -eq 'OperatingSystem'}).MountPoint

# Check for Mount Point
If (!($mountPoint)) {[System.Environment]::Exit(243)} # 243 will equal "Unable to detect Operating System Drive."

# Suspend Bitlocker on Operating System Volume
$Bitlocker = Get-BitLockerVolume -MountPoint $mountPoint
If ($Bitlocker.ProtectionStatus -eq 'On') {
    Try {Suspend-BitLocker -MountPoint $mountPoint -RebootCount 1 -Confirm:$false -ErrorAction Stop | Out-Null}
    Catch {[System.Environment]::Exit(244)} # 244 will equal "Unable to suspend Bitlocker."
    }

# Disable EnableVirtualizationBasedSecurity in Registry
Try {New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard -Name EnableVirtualizationBasedSecurity -PropertyType DWORD -Value 0 -Force -ErrorAction Stop | Out-Null}
Catch {[System.Environment]::Exit(245)} # 245 will equal "Unable to disable EnableVirtualizationBasedSecurity in Registry."

# Disable RequirePlatformSecurityFeaturesin Registry
Try {New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard -Name RequirePlatformSecurityFeatures -PropertyType DWORD -Value 0 -Force -ErrorAction Stop | Out-Null}
Catch {[System.Environment]::Exit(246)} # 246 will equal "Unable to disable RequirePlatformSecurityFeatures in Registry."

# Disable HypervisorEnforcedCodeIntegrity in Registry
Try {New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity -Name Enabled -PropertyType DWORD -Value 0 -Force -ErrorAction Stop | Out-Null}
Catch {[System.Environment]::Exit(247)} # 247 will equal "Unable to disable HypervisorEnforcedCodeIntegrity in Registry."

# Disable VT for Direct I/O in Dell Bios
Try {Start-Process -FilePath "$location\$dellBiosFile" -Wait -ErrorAction Stop}
Catch {[System.Environment]::Exit(248)} # 248 will equal "Unable to Disable VT for Direct I/O in Dell Bios"

# Exit Based on Error Codes
If ($error.count -eq 0) {[System.Environment]::Exit(3010)} # This will prompt for a Soft Restart in Software Center
Else {[System.Environment]::Exit(249)} # 249 will equal "Failed to run script. Please contact Client Engineering."
