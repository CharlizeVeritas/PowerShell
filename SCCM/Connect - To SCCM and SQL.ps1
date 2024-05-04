# SQL Configuration Variables
$SQL_Server = "xxx.yyy.com"
$SQL_Database = "xxx"
$SQL_Query = "EXEC stored_procedure_or_paste_query"

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

# Get SQL Table
Write-Host "Getting Data from SQL...`n" -ForegroundColor Cyan
Try {$SQL_Data = Invoke-Sqlcmd -ServerInstance $SQL_Server -Database $SQL_Database -Query $SQL_Query -ErrorAction Stop -WarningAction SilentlyContinue}
Catch {Write-Host "Error Retrieving SQL Data: $($_.Exception.Message)" -ForegroundColor Red;break}

# Show Results Count
If ($SQL_Data.Count -ne 0) {Write-Host "Found $($SQL_Data.Count) Results in Query!" -ForegroundColor Green}
Else {Write-Host "Query returned 0 results!" -ForegroundColor Red}

# Perform Work Steps Below
