# Configuration Manager Site configuration
$SiteCode = "XXX" # Site code 
$ProviderMachineName = "xxx.yyy.com" # SMS Provider machine name

# Configuration Manager Customizations
$initParams = @{}

# Clear Error Variable for Possible Reru
$error.Clear()

# Generate Timestamp for Report Naming
$timestamp = "$(Get-Date –format 'yyyyMMdd_HHmmss')"

# Import the ConfigurationManager.psd1 module 
If ((Get-Module ConfigurationManager) -eq $null) {Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams }

# Connect to the site's drive if it is not already present
If ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

# Get List File
[System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = $initialDirectory
$OpenFileDialog.filter = “All files (*.*)| *.*”
$OpenFileDialog.ShowDialog() | Out-Null
If ($OpenFileDialog.filename -like "*.txt") {
    Try {$Userlist = Get-Content -Path $OpenFileDialog.filename -ErrorAction Stop}
    Catch {Write-Host "Failed to get List File: $($_.Exception.Message)"}
    }
If ($OpenFileDialog.filename -like "*.csv") {
    Try {$Userlist = $(import-csv -Path $OpenFileDialog.filename -ErrorAction Stop).ComputerName}
    Catch {Write-Host "Failed to get List File: $($_.Exception.Message)"}
    }

# Confirm Input
If (!($Userlist)) {Write-Host "User List not found!" -ForegroundColor Red;break}

# Get Collection Name
Write-Host "Enter Collection Name: " -ForegroundColor Cyan -NoNewline; $Collection = Read-Host

# Confirm Input
If (!($Collection)) {Write-Host "Collection not entered!" -ForegroundColor Red;break}

# Add Computers to Collection
Write-Host "Found $($Userlist.Count) Computers`n" -ForegroundColor Cyan
$count=0
Foreach ($User in $Userlist) {
    $count++
    Write-Host "Adding $User to $Collection... ($count of $($Userlist.count))" -ForegroundColor Cyan
    Try {Add-CMUserCollectionDirectMembershipRule -CollectionName $Collection -ResourceID (Get-CMUser -Name "PUGET\$User" -ErrorAction Stop).ResourceID -ErrorAction Stop}
    Catch {Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red}
    }
