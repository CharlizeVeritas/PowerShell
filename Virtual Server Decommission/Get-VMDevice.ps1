<#
  .SYNOPSIS
  Gets a Device Record from the VMWare Server.

  .DESCRIPTION

  This script will get a Device Record from the VMWare Server. If the script
  encounters any error along the way it will output a  brief text explanation of
  the issue along with the exception message if present.

  .PARAMETER username
  Specifies the Username of the User with access to the Jump Server.

  .PARAMETER password
  Specifies the password of the User with access to the Jump Server.

  .PARAMETER JumpServer
  Specifies the Fully Qualified Domain Name (FQDN) of the Jump Server that contains
  the modules and dlls needed to run this script.

  .PARAMETER VMServer
  Specifies the Fully Qualified Domain Name (FQDN) of the VMWare Server.

  .PARAMETER vmhostname
  Specifies the Hostname / ServerName of the VM Server record to get. Note: This
  is the Fully Qualified Domain Name (FQDN) of the server.

  .PARAMETER VMUser
  Specifies the username of the user that has rights to the VMWare Server.

  .PARAMETER VMPass
  Specifies the password of the user that has rights to the VMWare Server.

  .OUTPUTS
  Get-VMDevice.ps1 will output any Exception Messages if they occur.

  .EXAMPLE
  PS> .\Get-VMDevice.ps1 -username XXXXX -password Password1! -JumpServer XXXXXXXXXX.yyyyy.com -VMServer YYYYY.domain.com -vmhostname YYYYY -VMUser ZZZZZ -VMPass Password1!
#>

Param([Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password,
    [Parameter(Mandatory=$true)][string]$JumpServer,
    [Parameter(Mandatory=$true)][string]$VMServer,
    [Parameter(Mandatory=$true)][string]$vmhostname,
    [Parameter(Mandatory=$true)][string]$VMUser,
    [Parameter(Mandatory=$true)][string]$VMPass
    )

# Create Credential Object from User Information
$PWord = ConvertTo-SecureString -String $password -AsPlainText -Force
Try {$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $PWord -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating credential object for $($username): $($_.Exception.Message)"}

# Create PS Session to Jumpserver
Try {$Session = New-PSSession -ComputerName $JumpServer -Credential $Credential -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating session to $($JumpServer): $($_.Exception.Message)"}

# Run Script on Jumpserver
Invoke-Command -Session $Session -Command {
param([string]$VMServer=$VMServer,
[string]$vmhostname=$vmhostname,
[string]$VMUser=$VMUser,
[string]$VMPass=$VMPass)

# Create Credential Object
$PWord = ConvertTo-SecureString -String $VMPass -AsPlainText -Force
Try {$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VMUser, $PWord -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating credential object for $($username): $($_.Exception.Message)"}

# Import the "VMware.VimAutomation.Core" module
If ((Get-Module "VMware.VimAutomation.Core" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue) -eq $null) {
    Try {Import-Module "VMware.VimAutomation.Core" -WarningAction SilentlyContinue -ErrorAction Stop}
    Catch {throw "FAILED: Error occured loading VMware.VimAutomation.Core module: $($_.Exception.Message)"}
    }

# Prevent Certificate Errors
Try {Set-PowerCLIConfiguration -Scope Session -DefaultVIServerMode Multiple -DisplayDeprecationWarnings:$false -InvalidCertificateAction Ignore -Confirm:$False -InformationAction SilentlyContinue -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null}
Catch {throw "FAILED: Error occured setting PowerCLI Configuration: $($_.Exception.Message)"}

# Connect to VM Server
Try {Connect-VIServer -Server $VMServer -Credential $Credential -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null}
Catch {throw "FAILED: Error occured connecting to $($VMServer): $($_.Exception.Message)"}

# Get Device Object from VMWare
Try {$Device = Get-VM -Name $vmhostname -Server $VMServer -WarningAction SilentlyContinue -ErrorAction Stop}
Catch {$Device = $null} # This is to completely supress any errors from Get-VM when device not found

# Output Results
If ($Device) {return "SUCCESS: Found Device ID $($Device.PersistentId) for $vmhostname on VMWare Server $VMServer"} Else {return "WARNING: No Device ID found for $vmhostname on VM server $VMServer (Please check manually)"}            

} -ErrorAction Stop -ArgumentList $VMServer,$vmhostname,$VMUser,$VMPass

# Remove PS Session to JumpServer
Try {Remove-PSSession -Session $Session -ErrorAction Stop}
Catch {throw "FAILED: Error occured removing session to $($JumpServer): $($_.Exception.Message)"}
