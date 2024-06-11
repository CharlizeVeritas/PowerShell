<#
  .SYNOPSIS
  Gets an IB Host Record from the Infoblox Server DNS table.

  .DESCRIPTION
  This script will get an IB Host Record from the Infoblox Server. If the script
  encounters any error along the way it will output a  brief text explanation of
  the issue along with the exception message if present.

  .PARAMETER InfoBloxServer
  Specifies the Fully Qualified Domain Name (FQDN) of the InfoBlox Server.

  .PARAMETER vmhostname
  Specifies the Hostname / ServerName of the VM Server record to get. Note: This is
  the Fully Qualified Domain Name (FQDN) of the server.

  .PARAMETER InfoBloxUser
  Specifies the username of the user that has rights to the InfoBlox Server.

  .PARAMETER InfoBloxPass
  Specifies the password of the user that has rights to the InfoBlox Server.

  .OUTPUTS
  Get-IBHostRecord.ps1 will output any Exception Messages if they occur.

  .EXAMPLE
  PS> .\Get-IBHostRecord.ps1 -InfoBloxServer YYYYY.domain.com -vmhostname YYYYY -InfoBloxUser ZZZZZ -InfoBloxPass Password1!
#>

Param([Parameter(Mandatory=$true)][string]$InfoBloxServer,
    [Parameter(Mandatory=$true)][string]$vmhostname,
    [Parameter(Mandatory=$true)][string]$InfoBloxUser,
    [Parameter(Mandatory=$true)][string]$InfoBloxPass
    )

# Clean $InfoBloxUser Input to remove Domain if Present
If ($InfoBloxUser -like "*\*") {$InfoBloxUser = $InfoBloxUser.Split("\")[1]}

# Create Credential Object
$PWord = ConvertTo-SecureString -String $InfoBloxPass -AsPlainText -Force
Try {$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $InfoBloxUser, $PWord -ErrorAction Stop}
Catch {throw "FAILED: Error occured creating credential object: $($_.Exception.Message)"}

# Get Host Record
Try {$HostRecord = Invoke-WebRequest -Credential $Credential -Uri "https://$InfoBloxServer/wapi/v2.10.5/record:host?name:=$vmhostname" -Method Get -ErrorAction Stop}
Catch {throw "FAILED: Error occured in getting Host Record for $($vmhostname) / $($_.Exception.Message)"}

# Get A Record
Try {$ARecord = Invoke-WebRequest -Credential $Credential -Uri "https://$InfoBloxServer/wapi/v2.10.5/record:a?name:=$vmhostname" -Method Get -ErrorAction Stop}
Catch {throw "FAILED: Error occured in getting A Record for $($vmhostname) / $($_.Exception.Message)"}

# get Host Record Information
If (($HostRecord.Content) -and ($HostRecord.Content -ne "[]")) {

    # Get Reference ID for Host Record and IP Address
    Try {$jsonContent = $HostRecord.Content | ConvertFrom-Json
    $jsonContent._ref -match "record:host/([^;]*):" | Out-Null
    $refnew = $Matches[1]
    $jsonContent = $jsonContent | select @{l='Ref_ID';e={$refnew}},@{l='Host';e={($_ | select -ExpandProperty ipv4addrs).host}},@{l='IPV4Addr';e={($_ | select -ExpandProperty ipv4addrs).ipv4addr}}
    $refid = $jsonContent.Ref_ID
    $ipaddress = $jsonContent.IPV4Addr
    $recordType = "Host"}
    Catch {throw "FAILED: Failed to convert Json Data: $($_.Exception.Message)"}
    }
ElseIf (($ARecord.Content) -and ($ARecord.Content -ne "[]")) {

    # Get Reference ID for A Record and IP Address
    Try {$jsonContent = $ARecord.Content | ConvertFrom-Json
    $jsonContent._ref -match "record:a/([^;]*):" | Out-Null
    $refnew = $Matches[1]
    $jsonContent = $jsonContent | select @{l='Ref_ID';e={$refnew}},@{l='Host';e={($_.name)}},@{l='IPV4Addr';e={($_.ipv4addr)}}
    $refid = $jsonContent.Ref_ID
    $ipaddress = $jsonContent.IPV4Addr
    $recordType = "A"}
    Catch {throw "FAILED: Failed to convert Json Data: $($_.Exception.Message)"}
    }

# Return if No reference Found
If ((!$refid) -or ($refid -eq $null) -or ($refid -eq "")) {return "WARNING: No Reference ID found for $($vmhostname) on InfoBlox Server $InfoBloxServer (Please check manually)"} else {return "SUCCESS: Found Reference ID $refid for $recordType Record $($vmhostname) with IP $ipaddress on InfoBlox Server $InfoBloxServer"}
