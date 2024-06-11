<#
  .SYNOPSIS
  Removes a Device Record from the SCOM Server.

  .DESCRIPTION

  This script will remove a Device Record from the SCOM Server. If the script
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
  Specifies the Hostname / ServerName of the VM Server record to remove. Note: This
  is not the Fully Qualified Domain Name (FQDN) of the server, but just the name.

  .PARAMETER SCOMUser
  Specifies the username of the user that has rights to the SCOM Server.

  .PARAMETER SCOMPass
  Specifies the password of the user that has rights to the SCOM Server.

  .OUTPUTS
  Remove-SCOMDevice.ps1 will output any Exception Messages if they occur.

  .EXAMPLE
  PS> .\Remove-SCOMDevice.ps1 -username XXXXX -password Password1! -JumpServer XXXXX.domain.com -SCOMServer2012 YYYYY.domain.com -SCOMServer2022 YYYYY.domain.com -vmhostname YYYYY -SCOMUser ZZZZZ -SCOMPass Password1!
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

# Define Functions
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

Function Remove-SCOMDevice {

Param([Parameter(Mandatory=$true)][string]$SCOMServer,
    [Parameter(Mandatory=$true)][int][ValidateSet(2012,2022)]$SCOMVersion,
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

# Get Agent Managed Computer Guid from $WindowsComputer object
$AMCguid = $WindowsComputer.Id.Guid

# Create Query for Agent Managed Computer Criteria
$query = [string]::Format("Id = '{0}'", $AMCguid.Trim())

# Create criteria for Agent Managed Computer
$AMCCriteria = New-Object Microsoft.EnterpriseManagement.Administration.AgentManagedComputerCriteria($query) -ErrorAction Stop

# Get Agent Managed Computer
$AMComputers = ($Administration.GetAgentManagedComputers($AMCCriteria))

# Define generic collection list which is required parameter for the SDK Delete Command
$AgentManagedComputerType = [Microsoft.EnterpriseManagement.Administration.AgentManagedComputer];
$GenericListType = [System.Collections.Generic.List``1]
$GenericList = $GenericListType.MakeGenericType($AgentManagedComputerType)
$AMCList = New-Object $GenericList.FullName -ErrorAction Stop

# Add each AMC in the array to the collection list
ForEach ($AMC in $AMComputers) {$AMCList.Add($AMC)}

# Delete the Agent in the Collection
Try {$Administration.DeleteAgentManagedComputers($AMCList)}
Catch {Throw "ERROR: Failed to Delete $vmhostname on SCOM server $($SCOMServer): $($_Exception.Message)"}

# Verify Device has been Removed
If ($SCOMVersion -eq 2022) {
    
    # Check for SCOM 2022 Device
    $SCOM2022Device = Get-SCOM2022Device -SCOMServer2022 $SCOMServer -vmhostname $vmhostname -SCOMUser $SCOMUser -SCOMPass $SCOMPass

    # Return Results
    If ($SCOM2022Device -like "SUCCESS*") {return "FAILED: Error occured removing GUID $($WindowsComputer.Id.Guid) for $($vmhostname) from SCOM Server $SCOMServer (Record Still Exists)"}
    Else {return "SUCCESS: Decommissioned GUID $($WindowsComputer.Id.Guid) for $vmhostname from SCOM server $SCOMServer"}

    }
If ($SCOMVersion -eq 2012) {
    
    # Check for SCOM 2012 Device
    $SCOM2012Device = Get-SCOM2012Device -SCOMServer2012 $SCOMServer -vmhostname $vmhostname -SCOMUser $SCOMUser -SCOMPass $SCOMPass

    # Return Results
    If ($SCOM2012Device -like "SUCCESS*") {return "FAILED: Error occured removing GUID $($WindowsComputer.Id.Guid) for $($vmhostname) from SCOM Server $SCOMServer (Device Still Exists)"}
    Else {return "SUCCESS: Decommissioned GUID $($WindowsComputer.Id.Guid) for $vmhostname from SCOM server $SCOMServer"}

    }
}

# Check for SCOM 2022 Device
$SCOM2022Device = Get-SCOM2022Device -SCOMServer2022 $SCOMServer2022 -vmhostname $vmhostname -SCOMUser $SCOMUser -SCOMPass $SCOMPass

# Check for SCOM 2012 Device if 2022 Device Not Found
If (!$SCOM2022Device) {$SCOM2012Device = Get-SCOM2012Device -SCOMServer2012 $SCOMServer2012 -vmhostname $vmhostname -SCOMUser $SCOMUser -SCOMPass $SCOMPass}

# Output Results if No Device found 
If ((!$SCOM2022Device) -and (!$SCOM2012Device)) {return "WARNING: No Device ID found for $vmhostname on SCOM server $SCOMServer2012 or $SCOMServer2022 (Please check manually)"}

# Remove SCOM 2022 Device if Found 
If ($SCOM2022Device) {$DeviceRemoval = Remove-SCOMDevice -SCOMServer $SCOMServer2022 -SCOMVersion 2022 -vmhostname $vmhostname -SCOMUser $SCOMUser -SCOMPass $SCOMPass}

# Remove SCOM 2012 Device if Found 
If ($SCOM2012Device) {$DeviceRemoval = Remove-SCOMDevice -SCOMServer $SCOMServer2012 -SCOMVersion 2012 -vmhostname $vmhostname -SCOMUser $SCOMUser -SCOMPass $SCOMPass}

# Return Results
If ($DeviceRemoval -like "SUCCESS:*") {return $DeviceRemoval} Else {Throw $DeviceRemoval}

} -ErrorAction Stop -ArgumentList $SCOMServer2012,$SCOMServer2022,$vmhostname,$SCOMUser,$SCOMPass

# Remove PS Session to JumpServer
Try {Remove-PSSession -Session $Session -ErrorAction Stop}
Catch {throw "FAILED: Error occured removing session to $($JumpServer): $($_.Exception.Message)"}
