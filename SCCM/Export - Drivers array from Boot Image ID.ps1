# Load Assemblies
Write-Host "Loading Assemblies..." -ForegroundColor Cyan
Try {[Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null}
Catch {Write-Host "Failed to Load Microsoft.VisualBasic assembly: $($_.Exception.Message)" -ForegroundColor Red; break}

# Prompt User for Boot Image Description
Write-Host "Prompting User for Boot Image ID..." -ForegroundColor Yellow
$BootImageID = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Boot Image ID", "Boot Image ID")
If ($BootImageID -eq "") {Write-Host "No Boot Image ID Provided. Exiting Script." -ForegroundColor Red; break}

# Configuration Manager Site configuration
$SiteCode = "XXX" # Site code 
$ProviderMachineName = "xxx.yyy.com" # SMS Provider machine name

# Configuration Manager Customizations
$initParams = @{}

# Import the ConfigurationManager.psd1 module
If ((Get-Module ConfigurationManager) -eq $null) {
    Write-Host "Loading SCCM Module..." -ForegroundColor Cyan
    Try {Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams -ErrorAction Stop}
    Catch {Write-Host "Failed to Load SCCM Module: $($_.Exception.Message)" -ForegroundColor Red; break}
    }

# Connect to the site's drive if it is not already present
If ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    Write-Host "Connecting to SCCM Site:$SiteCode..." -ForegroundColor Cyan
    Try {New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams -ErrorAction Stop}
    Catch {Write-Host "Failed to connect to $($SiteCode): $($_.Exception.Message)" -ForegroundColor Red; break}
    }

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

# Get Drivers from Boot Image
Write-Host "Getting Drivers in Boot Image $BootImageID..." -ForegroundColor Cyan
Try {$drivers = (Get-CMBootImage -Id $BootImageID -ErrorAction Stop).ReferencedDrivers.ID}
Catch {Write-Host "Failed to Load SCCM Module: $($_.Exception.Message)" -ForegroundColor Red; break}

# Create Array to Store Drivers
$Array = @()

# Add Drivers to Array
ForEach ($ID in $drivers) {
    $output = Get-CMDriver -Id $ID -fast -ErrorAction SilentlyContinue | Select-Object -Property CI_ID,LocalizedDisplayName,ObjectPath
    $Array += @{ID="$($output.CI_ID)";Name="$($output.LocalizedDisplayName)";Path="$($output.ObjectPath)"}
    }

# Clear Console to Prepare for Copy/Paste
Clear-Host

# Output Results to Console
Write-Host '$Drivers = [PSCustomObject]@('
Foreach ($obj in $Array) {Write-Host "@{ID=`"$($obj.ID)`";Name=`"$($obj.Name)`";Path=`"$($obj.Path)`"}"}
Write-Host ')'
