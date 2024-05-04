# Define Variables
$path = "C:\ProgramData\App-V"
$validPerms = @(
    @{IdentityReference='NT AUTHORITY\Authenticated Users';FileSystemRights='ReadAndExecute, Synchronize'}
    @{IdentityReference='NT AUTHORITY\SYSTEM';FileSystemRights='FullControl'}
    @{IdentityReference='BUILTIN\Administrators';FileSystemRights='FullControl'}
    @{IdentityReference='NT SERVICE\TrustedInstaller';FileSystemRights='FullControl'}
    )

# Check for Path
If (!(Test-Path -Path $path -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)) {return $false}

# Get Permissions
$permissions = Get-Acl -Path $path -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

# Evaluate Permissions
Foreach ($perm in $validPerms) {
    $check = $permissions.Access | Where {$_.IdentityReference -eq $perm.IdentityReference}
    If ($check.FileSystemRights -ne $perm.FileSystemRights) {return $false}
    }

# Return True
return $true
