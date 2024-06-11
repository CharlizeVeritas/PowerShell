<#
  .SYNOPSIS
  Gets a Device Record from the SCCM Server.

  .DESCRIPTION

  This script will get a Device Record from the SCCM Server. If the script
  encounters any error along the way it will output a  brief text explanation of
  the issue along with the exception message if present.

  .PARAMETER username
  Specifies the Username of the User with access to the Jump Server.

  .PARAMETER password
  Specifies the password of the User with access to the Jump Server.

  .PARAMETER JumpServer
  Specifies the Fully Qualified Domain Name (FQDN) of the Jump Server that contains
  the modules and dlls needed to run this script.

  .PARAMETER SCCMServer
  Specifies the Fully Qualified Domain Name (FQDN) of the SCCM Server.

  .PARAMETER SiteCode
  Specifies the Site Code for the Primary Site to access.

  .PARAMETER vmhostname
  Specifies the Hostname / ServerName of the VM Server record to get. Note: This is
  not the Fully Qualified Domain Name (FQDN) of the server, but just the name.

  .PARAMETER SCCMUser
  Specifies the username of the user that has rights to the SCCM Server.

  .PARAMETER SCCMPass
  Specifies the password of the user that has rights to the SCCM Server.

  .OUTPUTS
  Get-SCCMDevice.ps1 will output any Exception Messages if they occur.

  .EXAMPLE
  PS> .\Get-SCCMDevice.ps1 -username XXXXX -password Password1! -JumpServer XXXXXXXXXX.domain.com -SCCMServer YYYYY.domain.com -SiteCode XXX -vmhostname YYYYY -SCCMUser ZZZZZ -SCCMPass Password1!
#>

Param([Parameter(Mandatory=$true)][string]$username,
    [Parameter(Mandatory=$true)][string]$password,
    [Parameter(Mandatory=$true)][string]$JumpServer,
    [Parameter(Mandatory=$true)][string]$SCCMServer,
    [Parameter(Mandatory=$true)][string]$SiteCode,
    [Parameter(Mandatory=$true)][string]$vmhostname,
    [Parameter(Mandatory=$true)][string]$SCCMUser,
    [Parameter(Mandatory=$true)][string]$SCCMPass
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
param([string]$SCCMServer=$SCCMServer,
[string]$SiteCode=$SiteCode,
[string]$vmhostname=$vmhostname,
[string]$SCCMUser=$SCCMUser,
[string]$SCCMPass=$SCCMPass)

# Create Credential Object
$PWord = ConvertTo-SecureString -String $SCCMPass -AsPlainText -Force
Try {$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SCCMUser, $PWord -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating credential object for $($SCCMUser): $($_.Exception.Message)"}

# Clean $vmhostname in case FQDN was provided
If ($vmhostname -like "*.*") {$vmhostname = ($vmhostname.Split('.'))[0]}

# Configuration Manager Customizations
$initParams = @{}

# Import the ConfigurationManager.psd1 module
If ((Get-Module ConfigurationManager -WarningAction SilentlyContinue -ErrorAction SilentlyContinue) -eq $null) {Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue}

# Connect to the site's drive if it is not already present
If ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    Try {New-PSDrive -Name $SiteCode -Credential $credential -PSProvider CMSite -Root $SCCMServer @initParams -ErrorAction Stop | Out-Null}
    Catch {throw "FAILED: Error occured connecting PSDrive to SiteCode $($SiteCode): $($_.Exception.Message)"}
    }

# Set the current location to be the site code.
Try {Set-Location "$($SiteCode):\" @initParams -ErrorAction Stop}
Catch {throw "FAILED: Error occured setting location to SiteCode $($SiteCode): $($_.Exception.Message)"}

# Get Device Object from SCCM
Try {$Device = Get-cmdevice -Name $vmhostname -ErrorAction Stop}
Catch {$Device = $null} # This is to completely supress any errors from Get-cmdevice when device not found

# Output Results
If ($Device) {return "SUCCESS: Found Device ID $($Device.ResourceID) for $vmhostname in SiteCode $($SiteCode) on SCCM server $SCCMServer"} Else {return "WARNING: No Device ID found for $vmhostname in SiteCode $($SiteCode) on SCCM server $SCCMServer (Please check manually)"}

} -ErrorAction Stop -ArgumentList $SCCMServer,$SiteCode,$vmhostname,$SCCMUser,$SCCMPass

# Remove PS Session to JumpServer
Try {Remove-PSSession -Session $Session -ErrorAction Stop}
Catch {throw "FAILED: Error occured removing session to $($JumpServer): $($_.Exception.Message)"}
