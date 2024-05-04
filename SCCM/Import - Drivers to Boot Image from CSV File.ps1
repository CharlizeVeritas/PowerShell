<#
.SYNOPSIS

Adds Drivers to a Boot Image from a CSV list file.

.DESCRIPTION

Adds Drivers to a Boot Image in SCCM from a CSV list file including
Driver ID and Name. Will allow user to select the CSV file via an
Explorer Window and will provide a list of Boot Images from SCCM.

.INPUTS

None. You cannot pipe objects to this script.

.OUTPUTS

Output is provided via the Powershell Console.

.EXAMPLE

C:\> Powershell.exe -ExecutionPolicy ByPass -File "Add - Drivers to Boot Image from CSV File.ps1"
#>

# Configuration Manager Site configuration
$SiteCode = "xxx" # Site code 
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
$OpenFileDialog.filter = “csv files (*.csv)| *.csv”
$OpenFileDialog.ShowDialog() | Out-Null
If ($OpenFileDialog.filename -like "*.csv") {
    Try {$driverlist = $(import-csv -Path $OpenFileDialog.filename -ErrorAction Stop)}
    Catch {Write-Host "Failed to get List File: $($_.Exception.Message)"}
    }

# Fail if no $driverlist
If (!($driverlist)) {Write-Host "No Driver List provided. Exiting Script" -ForegroundColor Red; break}

# Get Boot Image
Write-Host "Getting List of Boot Images..." -ForegroundColor Cyan
$bootimages = Get-CMBootImage | Select PackageID, Name, Version, ImageOSVersion, ProductionClientVersion, ImagePath, DefaultImage, Description

# Select Boot Image
Write-Host "Waiting for user to select Boot Image..." -ForegroundColor Cyan
$bootimage = $bootimages | Out-GridView -Title "Select Boot Image" -PassThru

# Fail if no $bootimage
If (!($bootimage)) {Write-Host "No Boot Image Selected. Exiting Script" -ForegroundColor Red; break}

# Begin Count
$count = 0

# Add Drivers to Boot Image
Foreach ($driver in $driverlist) {
    $count++
    Write-Host "Adding $($driver.name) to $($bootimage.Name)... ($count of $($driverlist.count))" -ForegroundColor Cyan
    Try {Set-CMDriverBootImage -SetDriveBootImageAction AddDriverToBootImage -DriverId $($driver.ID) -BootImageId $($bootimage.PackageID) -ErrorAction Stop}
    Catch {Write-Host "Failed to add $($driver.name) to $($bootimage.Name): $($_.Exception.Message)" -ForegroundColor Red}
    }
