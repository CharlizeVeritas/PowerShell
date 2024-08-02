Write-Host "`nEnter Application Name: " -Foreground Green -NoNewLine; $AppName = Read-Host 

$32bit = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction Stop | Select DisplayName, DisplayVersion, Publisher, UninstallString, QuietUninstallString, PSPath
$64bit = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction Stop | Select DisplayName, DisplayVersion, Publisher, UninstallString, QuietUninstallString, PSPath
$Installed = $32bit + $64bit

$Installed | Where {$_.DisplayName -like "*$AppName*"} | %{Write-Host "`nName: $($_.DisplayName)  `nVersion: $($_.DisplayVersion) `nPublisher: $($_.Publisher) `nUninstallString: $($_.UninstallString) `nQuietUninstall: $($_.QuietUninstallString) `nPSPath: $($_.PSPath)"}
