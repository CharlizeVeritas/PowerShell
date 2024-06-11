<#
  .SYNOPSIS
  Gets a Device Record from the SCOM Server.

  .DESCRIPTION

  This script will get a Device Record from the SCOM Server. If the script
  encounters any error along the way it will output a  brief text explanation of
  the issue along with the exception message if present.

  .PARAMETER username
  Specifies the Username of the User with access to the Jump Server.

  .PARAMETER password
  Specifies the password of the User with access to the Jump Server.

  .PARAMETER JumpServer
  Specifies the Fully Qualified Domain Name (FQDN) of the Jump Server that contains
  the modules and dlls needed to run this script.

  .PARAMETER SCOMServer2012
  Specifies the Fully Qualified Domain Name (FQDN) of the 2012 SCOM Server.

  .PARAMETER SCOMServer2022
  Specifies the Fully Qualified Domain Name (FQDN) of the 2012 SCOM Server.

  .PARAMETER vmhostname
  Specifies the Hostname / ServerName of the VM Server record to get. Note: This is
  not the Fully Qualified Domain Name (FQDN) of the server, but just the name.

  .PARAMETER SCOMUser
  Specifies the username of the user that has rights to the SCOM Server.

  .PARAMETER SCOMPass
  Specifies the password of the user that has rights to the SCOM Server.

  .OUTPUTS
  Get-SCOMDevice.ps1 will output any Exception Messages if they occur.

  .EXAMPLE
  PS> .\Get-SCOMDevice.ps1 -username XXXXX -password Password1! -JumpServer XXXXX.domain.com -SCOMServer2012 YYYYY.domain.com -SCOMServer2022 YYYYY.domain.com -vmhostname YYYYY -SCOMUser ZZZZZ -SCOMPass Password1!
#>

Param([Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password,
    [Parameter(Mandatory=$true)][string]$JumpServer,
    [Parameter(Mandatory=$true)][string]$SCOMServer2012,
    [Parameter(Mandatory=$true)][string]$SCOMServer2022,
    [Parameter(Mandatory=$true)][string]$vmhostname,
    [Parameter(Mandatory=$true)][string]$SCOMUser,
    [Parameter(Mandatory=$true)][string]$SCOMPass
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
param([string]$SCOMServer2012=$SCOMServer2012,
[string]$SCOMServer2022=$SCOMServer2022,
[string]$vmhostname=$vmhostname,
[string]$SCOMUser=$SCOMUser,
[string]$SCOMPass=$SCOMPass)

# Import the OperationsManager.psd1 module
If ((Get-Module OperationsManager -WarningAction SilentlyContinue -ErrorAction SilentlyContinue) -eq $null) {Import-Module OperationsManagers -Force -InformationAction Ignore -WarningAction Ignore -ErrorAction SilentlyContinue}

Function Get-SCOM2012Device {

Param([Parameter(Mandatory=$true)][string]$SCOMServer2012,
    [Parameter(Mandatory=$true)][string]$vmhostname,
    [Parameter(Mandatory=$true)][string]$SCOMUser,
    [Parameter(Mandatory=$true)][string]$SCOMPass
    )

# Create Credential Object
$PWord = ConvertTo-SecureString -String $SCOMPass -AsPlainText -Force
Try {$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SCOMUser, $PWord -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating credential object for $($SCOMUser): $($_.Exception.Message)"}

# Create Connection to SCOM Server
Try {New-SCOMManagementGroupConnection -ComputerName $SCOMServer2012 -Credential $Credential -ErrorAction Stop}
Catch {throw "FAILED: Error occured connecting to SCOM Server $($SCOMServer2012): $($_.Exception.Message)"}

# Load Management Group object
Try {$ManagementGroup = Get-SCOMManagementGroup -ErrorAction Stop}
Catch {throw "FAILED: Error occured getting the Management Group from SCOM Server $($SCOMServer2012): $($_.Exception.Message)"}

# Get Administration object
Try {$Administration = $ManagementGroup.GetAdministration()}
Catch {throw "FAILED: Error occured getting the Administration object from SCOM Server $($SCOMServer2012): $($_.Exception.Message)"}

# Get all the Windows Computers into my Array
Try {$WindowsComputers = Get-SCOMClass -Name "Microsoft.Windows.Computer" -ErrorAction Stop | Get-SCOMClassInstance -ErrorAction Stop}
Catch {throw "FAILED: Error occured getting the Windows Computers SCOMClass from SCOM Server $($SCOMServer2012): $($_.Exception.Message)"}

# Create an empty Hashtable
$HashTable = @{}

# Fill the hashtable from the array using the unique FQDN as the Key
ForEach ($Computer in $WindowsComputers) {$HashTable.Add("$($Computer.DisplayName)",$Computer)} 

# Retrieve the individual matching object from the Hashtable
$WindowsComputer = $HashTable.($vmhostname)

# Return if no Windows Computer Found
If (!$WindowsComputer) {return $null} Else {return $($WindowsComputer | Select -Property *)}
}

Function Get-SCOM2022Device {

Param([Parameter(Mandatory=$true)][string]$SCOMServer2022,
    [Parameter(Mandatory=$true)][string]$vmhostname,
    [Parameter(Mandatory=$true)][string]$SCOMUser,
    [Parameter(Mandatory=$true)][string]$SCOMPass
    )

# Create Credential Object
$PWord = ConvertTo-SecureString -String $SCOMPass -AsPlainText -Force
Try {$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SCOMUser, $PWord -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating credential object for $($SCOMUser): $($_.Exception.Message)"}

# Create Connection to SCOM Server
Try {New-SCOMManagementGroupConnection -ComputerName $SCOMServer2022 -Credential $Credential -ErrorAction Stop}
Catch {throw "FAILED: Error occured connecting to SCOM Server $($SCOMServer2022): $($_.Exception.Message)"}

# Load Management Group object
Try {$ManagementGroup = Get-SCOMManagementGroup -ErrorAction Stop}
Catch {throw "FAILED: Error occured getting the Management Group from SCOM Server $($SCOMServer2022): $($_.Exception.Message)"}

# Get Administration object
Try {$Administration = $ManagementGroup.GetAdministration()}
Catch {throw "FAILED: Error occured getting the Administration object from SCOM Server $($SCOMServer2022): $($_.Exception.Message)"}

# Get all the Windows Computers into my Array
Try {$WindowsComputers = Get-SCOMClass -Name "Microsoft.Windows.Computer" -ErrorAction Stop | Get-SCOMClassInstance -ErrorAction Stop}
Catch {throw "FAILED: Error occured getting the Windows Computers SCOMClass from SCOM Server $($SCOMServer2022): $($_.Exception.Message)"}

# Create an empty Hashtable
$HashTable = @{}

# Fill the hashtable from the array using the unique FQDN as the Key
ForEach ($Computer in $WindowsComputers) {$HashTable.Add("$($Computer.DisplayName)",$Computer)} 

# Retrieve the individual matching object from the Hashtable
$WindowsComputer = $HashTable.($vmhostname)

# Return if no Windows Computer Found
If (!$WindowsComputer) {return $null} Else {return $($WindowsComputer | Select -Property *)}
}

# Check for SCOM 2022 Device
$SCOM2022Device = Get-SCOM2022Device -SCOMServer2022 $SCOMServer2022 -vmhostname $vmhostname -SCOMUser $SCOMUser -SCOMPass $SCOMPass

# Output Results if SCOM 2022 Device found 
If ($SCOM2022Device) {return "SUCCESS: Found Device ID $($SCOM2022Device.Id.Guid) for $vmhostname on SCOM server $SCOMServer2022"}

# Check for SCOM 2012 Device
$SCOM2012Device = Get-SCOM2012Device -SCOMServer2012 $SCOMServer2012 -vmhostname $vmhostname -SCOMUser $SCOMUser -SCOMPass $SCOMPass

# Output Results if SCOM 2012 Device found 
If ($SCOM2012Device) {return "SUCCESS: Found Device ID $($SCOM2012Device.Id.Guid) for $vmhostname on SCOM server $SCOMServer2012"}

# Return Warning if no Device ID Found
return "WARNING: No Device ID found for $vmhostname on SCOM server $SCOMServer2012 or $SCOMServer2022 (Please check manually)"

} -ErrorAction Stop -ArgumentList $SCOMServer2012,$SCOMServer2022,$vmhostname,$SCOMUser,$SCOMPass

# Remove PS Session to JumpServer
Try {Remove-PSSession -Session $Session -ErrorAction Stop}
Catch {throw "FAILED: Error occured removing session to $($JumpServer): $($_.Exception.Message)"}
