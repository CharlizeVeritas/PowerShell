# Load Assemblies
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
[void][System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”)
[void][System.Reflection.Assembly]::LoadWithPartialName(“ActiveDirectory”)

# Get Wim Desc
Write-Host "Provide AD Group Name..." -ForegroundColor Cyan
$group = [Microsoft.VisualBasic.Interaction]::InputBox("Provide AD Group Name", "AD Group Name", "")

# Fail if no $group
If (!($group)) {Write-Host "No AD Group Name provided. Exiting Script" -ForegroundColor Red; break}

# Get Group Object
Write-Host "Checking for $group..." -ForegroundColor Cyan
Try {$adgroup = Get-ADGroup -Identity $group -ErrorAction Stop}
Catch {Write-Host "Failed to find $group in AD: $($_.Exception.Message)";break}

# Get List File
Write-Host "Provide List File of Usernames..." -ForegroundColor Cyan
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = $initialDirectory
$OpenFileDialog.filter = “All files (*.*)| *.*”
$OpenFileDialog.ShowDialog() | Out-Null
If ($OpenFileDialog.filename -like "*.txt") {
    Try {$Userlist = Get-Content -Path $OpenFileDialog.filename -ErrorAction Stop}
    Catch {Write-Host "Failed to get List File: $($_.Exception.Message)"}
    }
If ($OpenFileDialog.filename -like "*.csv") {
    Try {$Userlist = $(import-csv -Path $OpenFileDialog.filename -ErrorAction Stop).UserName}
    Catch {Write-Host "Failed to get List File: $($_.Exception.Message)"}
    }

# Confirm Input
If (!($Userlist)) {Write-Host "User List not found!" -ForegroundColor Red;break}

# Add Users to Group
Write-Host "Found $($Userlist.Count) Computers`n" -ForegroundColor Cyan
$count=0
Foreach ($User in $Userlist) {
    $count++
    Write-Host "Adding $User to $Group... ($count of $($Userlist.count))" -ForegroundColor Cyan
    If ($User -like "* *") {
        $first = $User.Split(" ")[0]
        $last = $User.Split(" ")[1]        
        Try {$adUser = Get-ADUser -Filter "Name -eq '$last, $first'" -ErrorAction Stop}
        Catch {Write-Host "User not found: $($_.Exception.Message)" -ForegroundColor Red;$aduser = $null}        
        }
    Else {
        Try {$adUser = Get-ADUser -Identity $User -ErrorAction Stop}
        Catch {Write-Host "User not found: $($_.Exception.Message)" -ForegroundColor Red;$aduser = $null}
        }
    Try {Add-ADGroupMember -Identity $adGroup -Members $adUser -ErrorAction Stop}
    Catch {Write-Host "Error Adding $user to $($group): $($_.Exception.Message)" -ForegroundColor Red;$aduser = $null}
    }
