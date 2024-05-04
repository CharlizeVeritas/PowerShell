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
    Try {$computerlist = Get-Content -Path $OpenFileDialog.filename -ErrorAction Stop}
    Catch {Write-Host "Failed to get List File: $($_.Exception.Message)"}
    }
If ($OpenFileDialog.filename -like "*.csv") {
    Try {$computerlist = $(import-csv -Path $OpenFileDialog.filename -ErrorAction Stop).ComputerName}
    Catch {Write-Host "Failed to get List File: $($_.Exception.Message)"}
    }

# Confirm Input
If (!($computerlist)) {Write-Host "Computer List not found!" -ForegroundColor Red;break}

# Get Collection Name
Write-Host "Enter Collection Name: " -ForegroundColor Cyan -NoNewline; $Collection = Read-Host

# Confirm Input
If (!($Collection)) {Write-Host "Collection not entered!" -ForegroundColor Red;break}

# Add Computers to Collection
Write-Host "Found $($computerlist.Count) Computers`n" -ForegroundColor Cyan
$count=0
Foreach ($Computer in $computerlist) {
    $count++
    Write-Host "Adding $Computer to $Collection... ($count of $($computerlist.count))" -ForegroundColor Cyan
    Try {Add-CMDeviceCollectionDirectMembershipRule -CollectionName $Collection -ResourceID (Get-CMDevice -Name $Computer -ErrorAction Stop).ResourceID -ErrorAction Stop}
    Catch {Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red}
    }
