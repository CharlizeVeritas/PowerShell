# Define Variables
$PackageArray = @()
$nomad = $null
$nomadcopyloop = $null

# Get Nomad Logs
$nomad = Get-Content -Path C:\Windows\ccm\logs\NomadBranch.log -ErrorAction SilentlyContinue

# Search for Copy Loop
$nomadcopyloop = ($nomad | Select-String -pattern "Inside CopyLoopWait CopyError" -SimpleMatch)

# Continue if Loop is Present
If ($nomadcopyloop) {
    
    # Alert User
    Write-Host "`nCopy Loop found on $env:ComputerName!" -ForegroundColor Yellow

    # Add Packages to PackageArray
    Foreach ($Line in $nomadcopyloop) {
        $Package = $null
        $pattern = '(?<=\<).+?(?=\>)'
        Try {$Package = [regex]::Matches($Line, $pattern).Value[0]}
        Catch {Write-Host "Failed to find match in $($line): $($_.Exception.Message)" -ForegroundColor Red;$Package = $null}
        If ($Package) {$PackageArray += $Package}
        }
    
    # Remove Duplicates from PackageArray
    If ($PackageArray) {$PackageArray = $PackageArray | Select -Unique}

    # Remove Packages if PackageArray exists
    If ($PackageArray) {
        
        # Remove PackageIDs in PackageArray
        Foreach ($PackageID in $PackageArray) {
            Write-Host "Deleting Package: $PackageID" -ForegroundColor Cyan
            Try {Start-Process -FilePath "C:\Program Files\1E\Client\Extensibility\NomadBranch\CacheCleaner.exe" -ArgumentList "-DeletePkg=$PackageID -PkgVer=*" -WindowStyle Hidden -wait -ErrorAction Stop}
            Catch {Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red}
            }

        # Restart Nomad Service
        Write-Host "Restarting Nomad Service" -ForegroundColor Cyan
        Try {Restart-Service NomadBranch -Force -ErrorAction Stop}
        Catch {Write-Host "Failed to Restart Nomad Service: $($_.Exception.Message)" -ForegroundColor Red}

        # Restart ccmexec Service
        Write-Host "Restarting SMS Agent Host (ccmexec) Service" -ForegroundColor Cyan
        Try {Restart-Service ccmexec -Force -ErrorAction Stop}
        Catch {Write-Host "Failed to Restart SMS Agent Host (ccmexec) Service: $($_.Exception.Message)" -ForegroundColor Red}
        }
    }
