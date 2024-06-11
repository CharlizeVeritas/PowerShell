<#
  .SYNOPSIS
  Gets a Device Record from Active Directory.

  .DESCRIPTION

  This script will get a Device Record from Active Directory. If the script
  encounters any error along the way it will output a  brief text explanation of
  the issue along with the exception message if present.

  .PARAMETER username
  Specifies the Username of the User with access to the Jump Server.

  .PARAMETER password
  Specifies the password of the User with access to the Jump Server.

  .PARAMETER JumpServer
  Specifies the Fully Qualified Domain Name (FQDN) of the Jump Server that contains
  the modules and dlls needed to run this script.

  .PARAMETER vmhostname
  Specifies the Hostname / ServerName of the VM Server record to get. Note: This is
  not the Fully Qualified Domain Name (FQDN) of the server, but just the name.

  .PARAMETER ADUser
  Specifies the username of the user that has rights to Active Directory.

  .PARAMETER ADPass
  Specifies the password of the user that has rights to Active Directory.

  .OUTPUTS
  Get-ADDevice.ps1 will output any Exception Messages if they occur.

  .EXAMPLE
  PS> .\Get-ADDevice.ps1 -username XXXXX -password Password1! -JumpServer XXXXXXXXXX.domain.com -vmhostname YYYYY -ADUser ZZZZZ -ADPass Password1!
#>

Param([Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password,
    [Parameter(Mandatory=$true)][string]$JumpServer,
    [Parameter(Mandatory=$true)][string]$vmhostname,
    [Parameter(Mandatory=$true)][string]$ADUser,
    [Parameter(Mandatory=$true)][string]$ADPass
    )

# Create Credential Object from User Information
$PWord = ConvertTo-SecureString -String $password -AsPlainText -Force
Try {$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $PWord -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating credential object for $($username): $($_.Exception.Message)"}

# Clean $vmhostname in case FQDN was provided
If ($vmhostname -like "*.*") {$vmhostname = ($vmhostname.Split('.'))[0]}

# Create PS Session to Jumpserver
Try {$Session = New-PSSession -ComputerName $JumpServer -Credential $Credential -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating session to $($JumpServer): $($_.Exception.Message)"}

# Run Script on Jumpserver
Invoke-Command -Session $Session -Command {
param([string]$vmhostname=$vmhostname,
[string]$ADUser=$ADUser,
[string]$ADPass=$ADPass)

# Create Credential Object
$PWord = ConvertTo-SecureString -String $ADPass -AsPlainText -Force
Try {$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ADUser, $PWord -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating credential object for $($ADUser): $($_.Exception.Message)"}

# Import the ActiveDirectory module
If ((Get-Module ActiveDirectory -ErrorAction SilentlyContinue) -eq $null) {
    Try {Import-Module ActiveDirectory -WarningAction SilentlyContinue -ErrorAction Stop}
    Catch {throw "FAILED: Error occured loading ActiveDirectory module: $($_.Exception.Message)"}
    }

# Get Current Domain
$Domain = $((Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).Domain)

# Get Device Object from AD
Try {$Device = Get-ADComputer -Identity $vmhostname -Properties * -Credential $Credential -ErrorAction Stop}
Catch {$Device = $null} # This is to completely supress any errors from Get-ADComputer when device not found

# Output Results
If ($Device) {return "SUCCESS: Found ObjectGUID $($Device.ObjectGUID) for $vmhostname on Domain $Domain"} Else {return "WARNING: No ObjectGUID found for $vmhostname in Active Directory on Domain $Domain (Please check manually)"}

} -ErrorAction Stop -ArgumentList $vmhostname,$ADUser,$ADPass

# Remove PS Session to JumpServer
Try {Remove-PSSession -Session $Session -ErrorAction Stop}
Catch {throw "FAILED: Error occured removing session to $($JumpServer): $($_.Exception.Message)"}
