# Define Functions
Function Get-FileName($initialDirectory) {  
     [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
     $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
     $OpenFileDialog.initialDirectory = $initialDirectory
     $OpenFileDialog.filter = “All files (*.*)| *.*”
     $OpenFileDialog.ShowDialog() | Out-Null
     return $OpenFileDialog.filename
    }

# Get Computer List
$computerlist = Get-Content $(Get-FileName C:\)

# Output Total
$total = $computerlist.Count
Write-Host "Found $($computerlist.Count) without Logged on User" -ForegroundColor Cyan

# Start Counter
$count = 0

# Enumerate List
Foreach ($computer in $computerlist) {

    # Add to Counter
    $count+=1

    # Alert User
    Write-Host "Attempting connection to $computer ($count of $total)..." -ForegroundColor Cyan

    # Test Connection
    Try {$ping = Test-Connection $computer -Count 1 -ErrorAction Stop}
    Catch {Write-Host "Error! Failed to ping $computer! $($_.Exception.Message)" -ForegroundColor Red; $ping = $null}

    # Perform Tasks if Ping is present
    If ($ping) {

        # Create pssession
        Try {$session = new-pssession $computer -ErrorAction Stop}
        Catch {Write-Host "Error! Failed to connect to $computer! $($_.Exception.Message)" -ForegroundColor Red; $session = $null}

        # Perform Tasks if Session is present
        If ($session) {

            # Run Commands on Session
            Invoke-Command -Session $session -ScriptBlock {
        
                # Check for logged on user
                $username = (Get-WmiObject -Class Win32_Process -Filter 'Name="explorer.exe"')

                # If no Logged on user then restart
                If ($username) {Write-Host "Error! Found: $($username.GetOwner().User) No Restart Performed!" -ForegroundColor Red} Else {Write-Host "Success! Restarting $($env:computername)" -ForegroundColor Green; Restart-Computer -Force}
                }

            # Remove Session
            Remove-PSSession $session
            }
        }
    }
