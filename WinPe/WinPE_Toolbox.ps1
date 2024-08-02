<#
  .SYNOPSIS
  A simple GUI with WinPE Functions to aid in imaging Dell Windows computers.

  .DESCRIPTION
  
  This script will create an interactive GUI for the user to run certain actions
  in WindowsPE. It requires three Dell Command MulitPlatform Packages as well as
  the Dell SMBIOS PowerShell provider to be installed on the WinPE image. The
  three named Dell Multiplatform BIOS Settings Packages should be configured for
  your environment, but seperated by AHCI, RAID, and Other being the package
  that doesn't set the drive spefication. The Dell SMBIOS PowerShell Provider
  must be installed on the WinPE image to allow this script to confirm settings
  in the BIOS for determining what is set and if settings were actually changed.
  This script can also format the disk drive for UEFI in case the bitlocker key
  is not found or for troubleshooting as well as collect SCCM/MECM logs and copy
  them to a network location. (Files not included)

  .PARAMETER pxelocation
  Specifies the location in the WinPE Image where the PXE Files needed by this
  script are located. This is where the iconfile and BIOS files are stored.

  .PARAMETER iconfile
  Specifies the filename of the icon file in the pxelocation folder.

  .PARAMETER ahcibiosfile
  Specifies the filename of the Dell Command Mulitplatform Package with the BIOS
  settings for your organization with the drive setting set to AHCI.

  .PARAMETER raidbiosfile
  Specifies the filename of the Dell Command Mulitplatform Package with the BIOS
  settings for your organization with the drive setting set to RAID.

  .PARAMETER otherbiosfile
  Specifies the filename of the Dell Command Mulitplatform Package with the BIOS
  settings for your organization with the drive setting set to Not Configured.

  .PARAMETER uploadpath
  Specifies the network path to upload SCCM/MECM log files.

  .OUTPUTS
  WinPE_Toolbox.ps1 will output to a Windows Presentation Framwork GUI.

  .EXAMPLE
  PS> .\WinPE_Toolbox.ps1 -pxelocation "X:\WinPE_Toolbox" -iconfile "icon.ico" -ahcibiosfile "DELL_BIOS_SETTINGS_AHCI_x64.exe" -raidbiosfile "DELL_BIOS_SETTINGS_RAID_x64.exe" -otherbiosfile "DELL_BIOS_SETTINGS_OTHER_x64.exe" -uploadpath "\\server\folder\WinPE_Toolbox

  .EXAMPLE
  X:\> powershell.exe -executionpolicy bypass -file .\WinPE_Toolbox.ps1 -pxelocation "X:\WinPE_Toolbox" -iconfile "icon.ico" -ahcibiosfile "DELL_BIOS_SETTINGS_AHCI_x64.exe" -raidbiosfile "DELL_BIOS_SETTINGS_RAID_x64.exe" -otherbiosfile "DELL_BIOS_SETTINGS_OTHER_x64.exe" -uploadpath "\\server\folder\WinPE_Toolbox
#>

Param([Parameter(Mandatory=$true)][string]$pxelocation,
    [Parameter(Mandatory=$true)][string]$iconfile,
    [Parameter(Mandatory=$true)][string]$ahcibiosfile,
    [Parameter(Mandatory=$true)][string]$raidbiosfile,
    [Parameter(Mandatory=$true)][string]$otherbiosfile,
    [Parameter(Mandatory=$true)][string]$uploadpath
    )

# Script Variables
$Version = "1.00"

# Log File Array
$logfiles = @(
    @{Before='X:\windows\temp\smstslog\smsts.log';After="$($env:ComputerName)_PE_SMSTS_$timestamp.log"}
    @{Before='X:\windows\temp\smstslog\CAS.log';After="$($env:ComputerName)_PE_CAS_$timestamp.log"}
    @{Before='X:\windows\temp\smstslog\ContentTransferManager.log';After="$($env:ComputerName)_PE_ContentTransferManager_$timestamp.log"}
    @{Before='X:\windows\temp\smstslog\DataTransferService.log';After="$($env:ComputerName)_PE_DataTransferService_$timestamp.log"}
    @{Before='C:\_SMSTaskSequence\Logs\Smstslog\smsts.log';After="$($env:ComputerName)_OS_SMSTS_$timestamp.log"}
    @{Before='C:\windows\ccm\logs\Smstslog\smsts.log';After="$($env:ComputerName)_CCM_SMSTS_$timestamp.log"}
    @{Before='C:\windows\ccm\logs\smsts.log';After="$($env:ComputerName)_Complete_SMSTS_$timestamp.log"}
    @{Before='C:\windows\ccm\logs\CAS.log';After="$($env:ComputerName)_CCM_CAS_$timestamp.log"}
    @{Before='C:\windows\ccm\logs\ContentTransferManager.log';After="$($env:ComputerName)_CCM_ContentTransferManager_$timestamp.log"}
    @{Before='C:\windows\ccm\logs\DataTransferService.log';After="$($env:ComputerName)_CCM_DataTransferService_$timestamp.log"}
    @{Before='C:\windows\ccm\logs\UpdatesDeployment.log';After="$($env:ComputerName)_CCM_UpdatesDeployment_$timestamp.log"}
    @{Before='C:\windows\ccm\logs\UpdatesHandler.log';After="$($env:ComputerName)_CCM_UpdatesHandler_$timestamp.log"}
    @{Before='C:\windows\ccm\logs\WUAHandler.log';After="$($env:ComputerName)_CCM_WUAHandler_$timestamp.log"}
    )

# Set Current Location
If ((Test-Path $pxelocation -ErrorAction SilentlyContinue) -and ((Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue).Manufacturer -like "*Dell*")) {Set-Location -Path $pxelocation -ErrorAction Stop; $WinPE = $True} Else {$WinPE = $False}

# Find Icon File
If (Test-Path -Path "$pxelocation\$iconfile" -ErrorAction SilentlyContinue) {$IconVariable = "Icon=`"$pxelocation\$iconfile`""}
ElseIf (Test-Path -Path "C:\Windows\System32\$iconfile" -ErrorAction SilentlyContinue) {$IconVariable = "Icon=`"C:\Windows\System32\$iconfile`""}
Else {$IconVariable = $null}

# Load Assemblies
Try {[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')}
Catch {Write-Host "Failed to Load PresentationFramwork: $($_.Exception.Message)" -ForegroundColor Red;break}
If ($WinPE -eq $True) {
    Try {Import-Module -Name 'DellBIOSProvider' -ErrorAction Stop}
    Catch {Write-Host "Failed to Import DellBIOSProvider: $($_.Exception.Message)" -ForegroundColor Red;break}
    }

# Create XML
If ($WinPE -eq $True) {
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinPE Toolbox" Background="#58a3c3" Height="410" Width="410" Topmost="True" HorizontalAlignment="Center" VerticalAlignment="Center" WindowStartupLocation="CenterScreen" $IconVariable ResizeMode="CanMinimize">
    <Grid x:Name="Main_Grid" Width="400" Height="400">
        <Label x:Name="Main_Label" Content="WinPE Toolbox" HorizontalAlignment="Center" Margin="0,10,0,0" VerticalAlignment="Top" Foreground="White" Width="380" Height="45" FontFamily="Arial" FontWeight="Bold" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" FontSize="24"/>
        <Label x:Name="Version_Label" Content="Version: $Version" HorizontalAlignment="Left" Margin="305,340,0,0" VerticalAlignment="Top" Foreground="White" />
        <Grid x:Name="Button_Grid" Visibility="Visible">
            <Button x:Name="Collect_Logs_Button" Content="Collect Logs" HorizontalAlignment="Center" Margin="0,120,0,0" VerticalAlignment="Top" Width="150" Height="50"/>
            <Button x:Name="Format_Drive_Button" Content="Format Drive" HorizontalAlignment="Center" VerticalAlignment="Center" Width="150" Height="50"/>
            <Button x:Name="BIOS_Button" Content="Configure BIOS" HorizontalAlignment="Center" VerticalAlignment="Top" Width="150" Height="50" Margin="0,230,0,0"/>
        </Grid>
        <Grid x:Name="Bios_Grid" Visibility="Hidden">
            <Button x:Name="Ahci_BIOS_Button" Content="AHCI" HorizontalAlignment="Left" Margin="47,120,0,0" VerticalAlignment="Top" Width="150" Height="50"/>
            <Button x:Name="Asset_BIOS_Button" Content="Set Asset Tag" HorizontalAlignment="Left" Margin="202,120,0,0" VerticalAlignment="Top" Width="150" Height="50"/>
            <Button x:Name="Raid_BIOS_Button" Content="RAID" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="50" Margin="47,0,0,0"/>
            <Button x:Name="Other_BIOS_Button" Content="Other" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="50" Margin="202,0,0,0"/>
            <Button x:Name="BIOS_Main_Menu_Button" Content="Main Menu" HorizontalAlignment="Center" VerticalAlignment="Top" Width="150" Height="50" Margin="0,230,0,0"/>
        </Grid>
        <Grid x:Name="Asset_Grid" Visibility="Hidden">
            <Label x:Name="Asset_Textbox_Label" Content="Enter Asset Tag" HorizontalAlignment="Center" Margin="0,130,0,0" VerticalAlignment="Top" Foreground="White" Width="380" Height="45" FontFamily="Arial" FontWeight="Bold" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" FontSize="24"/>
            <TextBox x:Name="Asset_Textbox" HorizontalAlignment="Center" TextWrapping="Wrap" VerticalAlignment="Top" Width="150" Height="24" Margin="0,171,0,0" FontSize="18" VerticalContentAlignment="Center"/>
            <Button x:Name="Asset_Set_Button" Content="Set Asset Tag" HorizontalAlignment="Center" Margin="0,200,0,0" VerticalAlignment="Top" Width="130" Height="35"/>
            <Label x:Name="Asset_Result_Label" Content="" HorizontalAlignment="Center" Margin="0,257,0,0" VerticalAlignment="Top" Foreground="White" Width="380" Height="40" FontFamily="Arial" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" FontSize="14" FontWeight="Bold"/>
            <Button x:Name="Asset_Main_Menu_Button" Content="Return to Main Menu" HorizontalAlignment="Center" Margin="0,310,0,0" VerticalAlignment="Top" Width="150" Height="50"/>
        </Grid>
        <Grid x:Name="Output_Grid" Visibility="Hidden">
            <TextBox x:Name="Main_Textbox" Text="" HorizontalAlignment="Center" IsReadOnly="True" TextWrapping="Wrap" VerticalAlignment="Top" Width="350" Height="256" Margin="-3,50,0,0" VerticalScrollBarVisibility="Auto"/>
            <Button x:Name="Main_Menu_Button" Content="Return to Main Menu" HorizontalAlignment="Center" Margin="0,310,0,0" VerticalAlignment="Top" Width="150" Height="50"/>
        </Grid>
    </Grid>
</Window>
"@
}
ELSE {
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinPE Toolbox" Background="#58a3c3" Height="410" Width="410" Topmost="True" HorizontalAlignment="Center" VerticalAlignment="Center" WindowStartupLocation="CenterScreen" $IconVariable ResizeMode="CanMinimize">
    <Grid x:Name="Main_Grid" Width="400" Height="400">
        <Label x:Name="Main_Label" Content="WinPE Toolbox" HorizontalAlignment="Center" Margin="0,10,0,0" VerticalAlignment="Top" Foreground="White" Width="380" Height="45" FontFamily="Arial" FontWeight="Bold" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" FontSize="24"/>
        <Label x:Name="Version_Label" Content="Version: 1.0" HorizontalAlignment="Left" Margin="305,340,0,0" VerticalAlignment="Top" Foreground="White" />
        <Grid x:Name="Button_Grid" Visibility="Visible">
            <Button x:Name="Collect_Logs_Button" Content="Collect Logs" HorizontalAlignment="Center" Margin="0,145,0,0" VerticalAlignment="Top" Width="150" Height="50"/>
            <Button x:Name="Format_Drive_Button" Content="Format Drive" HorizontalAlignment="Center" VerticalAlignment="Top" Width="150" Height="50" Margin="0,205,0,0"/>
        </Grid>
        <Grid x:Name="Output_Grid" Visibility="Hidden">
            <TextBox x:Name="Main_Textbox" Text="" HorizontalAlignment="Center" IsReadOnly="True" TextWrapping="Wrap" VerticalAlignment="Top" Width="350" Height="256" Margin="-3,50,0,0"/>
            <Button x:Name="Main_Menu_Button" Content="Return to Main Menu" HorizontalAlignment="Center" Margin="0,310,0,0" VerticalAlignment="Top" Width="150" Height="50"/>
        </Grid>
    </Grid>
</Window>
"@
}

# Create Window from XML
Try {$reader = (New-Object System.Xml.XmlNodeReader $xaml)}
Catch {Write-Host "Failed to Read XML: $($_.Exception.Message)" -ForegroundColor Red;break}
Try {$window = [Windows.Markup.XamlReader]::Load($reader)}
Catch {Write-Host "Failed to Load XML: $($_.Exception.Message)" -ForegroundColor Red;break}

# Create Controls
$xaml.SelectNodes("//*") | Where {$_.Name -ne 'Window'} | %{Set-Variable -Name "$($_.Name)" -Value $window.FindName($_.Name) -ErrorAction Stop}

# Set Version Label
$Version_Label.Content = "Version = $Version"

# Gui Functions
Function Main-Menu {

    # Clear Errors
    $error.Clear()

    # Set Background
    $window.Background = "#58a3c3"

    # Adjust Grids
    $Output_Grid.Visibility="Hidden"
    If ($Bios_Grid) {$Bios_Grid.Visibility="Hidden"}
    If ($Asset_Grid) {$Asset_Grid.Visibility="Hidden"}
    $Button_Grid.Visibility="Visible"
  
    # Clear Main_Textbox
    $Main_Textbox.Clear()

    }
Function Bios-Menu {
    
    # Clear Errors
    $error.Clear()

    # Set Background
    $window.Background = "#58a3c3"

    # Adjust Grids
    $Bios_Grid.Visibility="Visible"
    $Button_Grid.Visibility="Hidden"
    
    }
Function Asset-Menu {

    # Clear Errors
    $error.Clear()

    # Set Background
    $window.Background = "#58a3c3"

    # Adjust Grids
    $Bios_Grid.Visibility="Hidden"
    $Button_Grid.Visibility="Hidden"
    $Asset_Grid.Visibility="Visible"

    # Clear Asset Textbox
    $Asset_Textbox.Clear()

    # Clear Label
    $Asset_Result_Label.Content = ""

    # Focus on Asset Textbox
    $Asset_Textbox.Focus()
    
    }
Function Update-Main-Textbox {
    param(
        [Parameter(Mandatory)]
        [string]$Text
        )    
    
    # Set Main_Textbox
    $Main_Textbox.AddText("$Text`n")

    # Refresh GUI
    $Window.Dispatcher.Invoke([action]{$Main_Textbox},"Render")    
    
    }
Function Update-Asset-Label {
    param(
        [Parameter(Mandatory)]
        [string]$Content
        )    

    # Clear Label
    $Asset_Result_Label.Content = ""
    
    # Set Main_Textbox
    $Asset_Result_Label.Content = $Content

    # Refresh GUI
    $Window.Dispatcher.Invoke([action]{$Asset_Result_Label},"Render")    
    
    }

# Task Functions
Function Get-Output {
    param(
        [Parameter(Mandatory)]
        [string]$WorkingDirectory,
        [Parameter(Mandatory)]
        [string]$FileName,
        [Parameter(Mandatory)]
        [string]$Arguments
        )
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
        WorkingDirectory = $WorkingDirectory;
        FileName = $FileName;
        Arguments = $Arguments;
        CreateNoWindow = $True;
        WindowStyle = 'Hidden';
        RedirectStandardError = $True;
        RedirectStandardOutput = $True;
        UseShellExecute = $false
        }
    $Process = New-Object System.Diagnostics.Process -Property @{StartInfo = $ProcessInfo}
    $Process.Start() | Out-Null
    $Process.WaitForExit()
    return $Process.StandardOutput.ReadToEnd()  
      
    }
Function Collect-Logs {
    
    # Adjust Grids
    $Button_Grid.Visibility="Hidden"
    $Output_Grid.Visibility="Visible"

    # Clear Main_Textbox
    $Main_Textbox.Clear()
    
    # Generate Timestamp for File Naming
    $timestamp = "$(Get-Date –format 'yyyyMMdd_HHmmss')"

    # Get User Credentials
    If (!($creds)) {
        Update-Main-Textbox -Text "Please provide Credentials to connect to $uploadpath"
        $Window.TopMost = $False        
        Try {$script:creds = Get-Credential -Message "Enter your Domain Credentials to Connect to: `r`n`r`n$uploadpath" -ErrorAction Stop}
        Catch {Update-Main-Textbox -Text "Failed to get Credentials: $($_.Exception.Message)";$Window.TopMost = $True;break}
        $Window.TopMost = $True
        }

    # Map Drive to $uploadpath
    If (!(Test-Path -Path Upload: -ErrorAction SilentlyContinue)) {
        Try {New-PSDrive -Name "Upload" -PSProvider "FileSystem" -Root $uploadpath -Credential $creds -Description "Log Upload Folder" -ErrorAction Stop | Out-Null}
        Catch {Update-Main-Textbox -Text "Failed to connect to $($uploadpath): $($_.Exception.Message)";break}
        }

    # Get Username from Creds and 
    If ($creds.UserName -like "*\*") {$Username = ($creds.UserName).Split("\")[1]} Else {$Username = $creds.UserName}

    # Test Path before Continuing
    If (Test-Path -Path Upload: -ErrorAction SilentlyContinue) {Update-Main-Textbox -Text "Successfully connected to $uploadpath"}

    # Create Folder On $uploadpath
    If (!(Test-Path -Path "Upload:\$Username")) {
        Update-Main-Textbox -Text "Creating $uploadpath\$Username"
        Try {New-Item -Path "Upload:\$Username" -ItemType Directory -ErrorAction Stop | Out-Null}
        Catch {$Main_Textbox.AddText("Failed to create $uploadpath\$($Username): $($_.Exception.Message)`n")}
        }

    # Copy Log Files
    If (Test-Path -Path "Upload:\$Username") {
        Foreach ($log in $logfiles) {
            If (Test-Path $log.Before -ErrorAction SilentlyContinue) {
                Update-Main-Textbox -Text "Uploading $($log.Before)"
                Try {Copy-Item -Path $log.Before -Destination "Upload:\$Username\$($log.After)" -ErrorAction Stop | Out-Null}
                Catch {Update-Main-Textbox -Text "Failed to copy $log.Before to $uploadpath\$($Username): $($_.Exception.Message)"}
                }
            }
        }

    # Remove Mapped Drive
    If (Test-Path -Path Upload -ErrorAction SilentlyContinue) {Remove-PSDrive -Name Upload -ErrorAction SilentlyContinue | Out-Null}

    # Alert User
    If ($error.Count -eq 0) {Update-Main-Textbox -Text "Files uploaded to $uploadpath\$Username";Update-Main-Textbox -Text "Success!"}
    Else {Update-Main-Textbox -Text "Error Detected!";$window.Background = "#CF1523"}

    }
Function Format-Drive {
    
    # Adjust Grids
    $Button_Grid.Visibility="Hidden"
    $Output_Grid.Visibility="Visible"
    
    # Clear Main_Textbox
    $Main_Textbox.Clear()

    # Prompt for Confirmation
    Update-Main-Textbox -Text "Waiting for Confirmation..."
    $msgBoxInput =  [System.Windows.MessageBox]::Show('Are you sure you want to Format Drive 0 for Imaging?','Format Drive Confirmation','YesNo','Warning')

    # Process Request
    If ($msgBoxInput -eq 'Yes') {
    
        # Clear Drive 0
        Update-Main-Textbox -Text "Clearing Data on Drive 0..."
        Try {Get-Disk -Number 0  -ErrorAction Stop | Clear-Disk -RemoveData -Confirm:$false -RemoveOEM -ErrorAction Stop}
        Catch {Update-Main-Textbox -Text "Failed to Clear Drive 0: $($_.Exception.Message)";$window.Background = "#CF1523";break}

        # Initialize Drive 0
        If ($error.Count -eq 0) {
            Update-Main-Textbox -Text "Initializing Drive 0..."
            Try {Initialize-Disk -Number 0 -ErrorAction Stop}
            Catch {Update-Main-Textbox -Text "Failed to Initialize Drive 0: $($_.Exception.Message)";$window.Background = "#CF1523";break}
            }

        # Set Drive to GPT
        If ($error.Count -eq 0) {
            Update-Main-Textbox -Text "Converting Drive 0 to GPT..."
            Try {Set-Disk -Number 0 -PartitionStyle GPT -ErrorAction Stop}
            Catch {Update-Main-Textbox -Text "Failed to Convert Drive 0 to GPT: $($_.Exception.Message)";$window.Background = "#CF1523";break}
            }

        # Create EFI Partition
        If ($error.Count -eq 0) {
            Update-Main-Textbox -Text "Creating EFI Partition..."
            Try {New-Partition -DiskNumber 0 -Size 100MB -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -DriveLetter K -ErrorAction Stop}
            Catch {Update-Main-Textbox -Text "Failed to Create EFI Partition: $($_.Exception.Message)";$window.Background = "#CF1523";break}
            }

        # Format EFI Partition
        If ($error.Count -eq 0) {
            Update-Main-Textbox -Text "Formatting EFI Partition..."
            Try {Format-Volume -DriveLetter K -FileSystem FAT32 -ErrorAction Stop}
            Catch {Update-Main-Textbox -Text "Failed to Format EFI Partition: $($_.Exception.Message)";$window.Background = "#CF1523";break}
            }

        # Create MSR Partition
        If ($error.Count -eq 0) {
            Update-Main-Textbox -Text "Creating MSR Partition..."
            Try {New-Partition -DiskNumber 0 -Size 128MB -GptType "{e3c9e316-0b5c-4db8-817d-f92df00215ae}" -ErrorAction Stop}
            Catch {Update-Main-Textbox -Text "Failed to Create MSR Partition: $($_.Exception.Message)";$window.Background = "#CF1523";break}
            }

        # Create Primary Partition
        If ($error.Count -eq 0) {
            Update-Main-Textbox -Text "Creating Primary Partition..."
            Try {New-Partition -DiskNumber 0 -UseMaximumSize -DriveLetter C -ErrorAction Stop}
            Catch {Update-Main-Textbox -Text "Failed to Create Primary Partition: $($_.Exception.Message)";$window.Background = "#CF1523";break}
            }

        # Format Primary Partition
        If ($error.Count -eq 0) {
            Update-Main-Textbox -Text "Formatting Primary Partition..."
            Try {Format-Volume -DriveLetter C -FileSystem NTFS -ErrorAction Stop}
            Catch {Update-Main-Textbox -Text "Failed to Format Primary Partition: $($_.Exception.Message)";$window.Background = "#CF1523";break}
            }

        # Alert User
        If ($error.Count -eq 0) {Update-Main-Textbox -Text "Complete!"} Else {Update-Main-Textbox -Text "Failure Detected!";$window.Background = "#CF1523"}
        }
    Else {Update-Main-Textbox -Text "Process aborted"}
   
    }
Function Set-BIOS-AHCI {
    
    # Adjust Grids
    $Button_Grid.Visibility="Hidden"
    $BIOS_Grid.Visibility="Hidden"
    $Output_Grid.Visibility="Visible"
    
    # Clear Main_Textbox
    $Main_Textbox.Clear()

    # Check for BIOS File
    If (!(Test-Path -Path "$pxelocation\$biosfile" -ErrorAction SilentlyContinue)) {$window.Background = "#CF1523";Update-Main-Textbox -Text "$biosfile is missing from $($pxelocation)`nCannot Proceed.";return}
    
    # Check if BIOS is set to AHCI
    Update-Main-Textbox -Text "Checking Drive Setting..."
    $output = (Get-Item -Path DellSmbios:\SystemConfiguration\EmbSataRaid).CurrentValue

    # Evaluate Output
    If ($output -eq "AHCI") {Update-Main-Textbox -Text "Drive is set to AHCI"} Else {Update-Main-Textbox -Text "Drive is NOT set to AHCI. Restart Required!";$window.Background = "#E0D23F"}

    # Update BIOS Settings
    Update-Main-Textbox -Text "Appying BIOS Settings..."
    Try {Start-Process -FilePath "$pxelocation\$ahcibiosfile" -Wait -ErrorAction Stop}
    Catch {Update-Main-Textbox -Text "Failed to Run BIOS Settings File:`n$($_.Exception.Message)";$window.Background = "#CF1523";return}

    # Success Message
    Switch ($output) {
        "Ahci" {Update-Main-Textbox -Text "BIOS Settings applied Successfully!"}
        default {Update-Main-Textbox -Text "BIOS Settings applied Successfully but a Restart is required before you can image!"
            
            # Prompt for Confirmation
            Update-Main-Textbox -Text "Waiting for Confirmation..."
            $msgBoxInput =  [System.Windows.MessageBox]::Show("Device must be restarted for imaging to work!`n`nWould you like to restart now?",'Restart Computer','YesNo','Warning')

            # Process Request
            If ($msgBoxInput -eq 'Yes') {Restart-Computer -Force -ErrorAction Stop} Else {$window.Background = "#CF1523";Update-Main-Textbox -Text "User declined restart, but restart is still required!"}
            
            }
        }
    }
Function Set-BIOS-RAID {
    
    # Adjust Grids
    $Button_Grid.Visibility="Hidden"
    $BIOS_Grid.Visibility="Hidden"
    $Output_Grid.Visibility="Visible"
    
    # Clear Main_Textbox
    $Main_Textbox.Clear()

    # Check for BIOS File
    If (!(Test-Path -Path "$pxelocation\$raidbiosfile" -ErrorAction SilentlyContinue)) {$window.Background = "#CF1523";Update-Main-Textbox -Text "$raidbiosfile is missing from $($pxelocation)`nCannot Proceed.";return}
    
    # Check if BIOS is set to AHCI
    Update-Main-Textbox -Text "Checking Drive Setting..."
    $output = (Get-Item -Path DellSmbios:\SystemConfiguration\EmbSataRaid).CurrentValue

    # Evaluate Output
    If ($output -eq "RAID") {Update-Main-Textbox -Text "Drive is set to RAID"} Else {Update-Main-Textbox -Text "Drive is NOT set to RAID. Restart Required!";$window.Background = "#E0D23F"}

    # Update BIOS Settings
    Update-Main-Textbox -Text "Appying BIOS Settings..."
    Try {Start-Process -FilePath "$pxelocation\$raidbiosfile" -Wait -ErrorAction Stop}
    Catch {Update-Main-Textbox -Text "Failed to Run BIOS Settings File:`n$($_.Exception.Message)";$window.Background = "#CF1523";return}

    # Success Message
    Switch ($output) {
        "Raid" {Update-Main-Textbox -Text "BIOS Settings applied Successfully!"}
        default {Update-Main-Textbox -Text "BIOS Settings applied Successfully but a Restart is required before you can image!"
            
            # Prompt for Confirmation
            Update-Main-Textbox -Text "Waiting for Confirmation..."
            $msgBoxInput =  [System.Windows.MessageBox]::Show("Device must be restarted for imaging to work!`n`nWould you like to restart now?",'Restart Computer','YesNo','Warning')

            # Process Request
            If ($msgBoxInput -eq 'Yes') {Restart-Computer -Force -ErrorAction Stop} Else {$window.Background = "#CF1523";Update-Main-Textbox -Text "User declined restart, but restart is still required!"}
            
            }
        }
    }
Function Set-BIOS-Other {
    
    # Adjust Grids
    $Button_Grid.Visibility="Hidden"
    $BIOS_Grid.Visibility="Hidden"
    $Output_Grid.Visibility="Visible"
    
    # Clear Main_Textbox
    $Main_Textbox.Clear()

    # Check for BIOS File
    If (!(Test-Path -Path "$pxelocation\$otherbiosfile" -ErrorAction SilentlyContinue)) {$window.Background = "#CF1523";Update-Main-Textbox -Text "$otherbiosfile is missing from $($pxelocation)`nCannot Proceed.";return}
    
    # Update BIOS Settings
    Update-Main-Textbox -Text "Appying BIOS Settings..."
    Try {Start-Process -FilePath "$pxelocation\$otherbiosfile" -Wait -ErrorAction Stop}
    Catch {Update-Main-Textbox -Text "Failed to Run BIOS Settings File:`n$($_.Exception.Message)";$window.Background = "#CF1523";return}

    # Success Message
    Update-Main-Textbox -Text "BIOS Settings applied Successfully!"

    }
Function Set-Asset-Tag {
    
    # Clear Label
    $Asset_Result_Label.Content = ""

    # Get Current Asset Tag
    $AssetTag = (Get-Item -Path DellSmbios:\SystemInformation\assettag).CurrentValue

    # Check Asset_Textbox for Text
    If (($Asset_Textbox.Text -ne "") -and ($Asset_Textbox.Text -ne $Null)) {
        
        # Set Asset Tag
        Update-Asset-Label -Content "Setting $($Asset_Textbox.Text) as Asset Tag..."
        Try {Set-Item -Path DellSmbios:\SystemInformation\assettag $($Asset_Textbox.Text) -ErrorAction Stop}
        Catch {$window.Background = "#CF1523";Update-Asset-Label -Content "Error: $($_.Exception.Message)";return}

        # Verify Asset Tag
        If ((Get-Item -Path DellSmbios:\SystemInformation\assettag).CurrentValue -eq $Asset_Textbox.Text) {Update-Asset-Label -Content "Success! Asset Tag = $($Asset_Textbox.Text)";$success = $true}
        Else {Update-Asset-Label -Content "Failure! Asset Tag = $((Get-Item -Path DellSmbios:\SystemInformation\assettag).CurrentValue)";$window.Background = "#CF1523";$success = $false}

        # Prompt for Restart if Needed
        If (((Get-Item -Path DellSmbios:\SystemInformation\assettag).CurrentValue -ne $AssetTag) -and ($success -eq $true)) {
            
            # Prompt for Confirmation
            Update-Main-Textbox -Text "Waiting for Confirmation..."
            $msgBoxInput =  [System.Windows.MessageBox]::Show("Device must be restarted for Asset Tag change!`n`nWould you like to restart now?",'Restart Computer','YesNo','Warning')

            # Process Request
            If ($msgBoxInput -eq 'Yes') {Restart-Computer -Force -ErrorAction Stop} Else {$window.Background = "#CF1523";Update-Asset-Label -Text "User declined restart! Restart required!"}            
            }

        }
    }

# Define Buttons
$Main_Menu_Button.Add_Click({Main-Menu})
$Collect_Logs_Button.Add_Click({Collect-Logs})
$Format_Drive_Button.Add_Click({Format-Drive})
If ($BIOS_Button) {$BIOS_Button.Add_Click({BIOS-Menu})}
If ($Ahci_BIOS_Button) {$Ahci_BIOS_Button.Add_Click({Set-BIOS-AHCI})}
If ($Raid_BIOS_Button) {$Raid_BIOS_Button.Add_Click({Set-BIOS-RAID})}
If ($Other_BIOS_Button) {$Other_BIOS_Button.Add_Click({Set-BIOS-Other})}
If ($BIOS_Main_Menu_Button) {$BIOS_Main_Menu_Button.Add_Click({Main-Menu})}
If ($Asset_BIOS_Button) {$Asset_BIOS_Button.Add_Click({Asset-Menu})}
If ($Asset_Set_Button) {$Asset_Set_Button.Add_Click({Set-Asset-Tag})}
If ($Asset_Main_Menu_Button) {$Asset_Main_Menu_Button.Add_Click({Main-Menu})}

# Show Window
$window.ShowDialog() | Out-Null
