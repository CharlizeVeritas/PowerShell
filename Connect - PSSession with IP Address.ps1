Write-Host "Enter IP Address:" -ForegroundColor Cyan -NoNewline;[string]$IP = Read-Host
Try {Set-Item WSMan:\localhost\Client\TrustedHosts -Value $IP -Force -ErrorAction Stop}
Catch {Write-Host "Failed to add $($IP) to the trusted hosts: $($_.Exception.Message)" -ForegroundColor Red}
Try {Enter-PSSession -Authentication Negotiate -ComputerName $IP -ErrorAction Stop}
Catch {Write-Host "Failed to Connect to $($IP): $($_.Exception.Message)" -ForegroundColor Red}
#Clear-Item WSMan:\localhost\Client\TrustedHosts -Force # Run this line manually after Exit-PSession.
