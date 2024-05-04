# Get SecurityServicesRunning
$SecurityServicesRunning = (Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).SecurityServicesRunning

# Get Drivers with Error Code 39
$DeviceError = Get-WmiObject -Class Win32_PnpEntity -ComputerName localhost -Namespace Root\CIMV2 | Where-Object {$_.ConfigManagerErrorCode -eq 39}

# Eval Conditions
If (($DeviceError) -and ($SecurityServicesRunning -contains 2)) {return $false} else {return $true}
