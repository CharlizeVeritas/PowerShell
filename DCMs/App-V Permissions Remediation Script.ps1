# Define Variables
$path = "C:\ProgramData\App-V"
$validPerms = @(
    @{IdentityReference='NT AUTHORITY\Authenticated Users';FileSystemRights='ReadAndExecute, Synchronize'}
    @{IdentityReference='NT AUTHORITY\SYSTEM';FileSystemRights='FullControl'}
    @{IdentityReference='BUILTIN\Administrators';FileSystemRights='FullControl'}
    @{IdentityReference='NT SERVICE\TrustedInstaller';FileSystemRights='FullControl'}
    )

# Create Path if Not Present
If (!(Test-Path -Path $path -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)) {New-Item -Path "C:\ProgramData" -Name "App-V" -ItemType "directory" -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null}

# Get Permissions on Path
$Acl = Get-Acl $path -ErrorAction Stop -WarningAction SilentlyContinue

# Set Owner
$Acl.SetOwner([System.Security.Principal.NTAccount] 'NT AUTHORITY\SYSTEM')
Set-Acl -Path $path -AclObject $Acl -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null

# SetAccessRuleProtection
$Acl.SetAccessRuleProtection($true, $true)
Set-Acl -Path $path -AclObject $Acl -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null

# Get Permissions on Path
$Acl = Get-Acl $path -ErrorAction Stop -WarningAction SilentlyContinue

# Set Permssions on Path
Foreach ($perm in $validPerms) {
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$($perm.IdentityReference)","$($perm.FileSystemRights)", "ContainerInherit,ObjectInherit", "None", "Allow") -ErrorAction Stop -WarningAction SilentlyContinue
    $Acl.SetAccessRule($rule) | Out-Null
    Set-Acl -Path $path -AclObject $Acl -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
    }

# Get Permissions on Path
$Acl = Get-Acl $path -ErrorAction Stop -WarningAction SilentlyContinue

# Remove Extra Permissions on Path
Foreach ($perm in $Acl.Access) {
    If ($perm.IdentityReference -notin $validPerms.IdentityReference) {
        If ($perm.FileSystemRights -eq "268435456") {$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$($perm.IdentityReference)","FullControl", "$($perm.InheritanceFlags)", "$($perm.PropagationFlags)", "$($perm.AccessControlType)") -ErrorAction Stop -WarningAction SilentlyContinue}
        Else {$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$($perm.IdentityReference)","$($perm.FileSystemRights)", "$($perm.InheritanceFlags)", "$($perm.PropagationFlags)", "$($perm.AccessControlType)") -ErrorAction Stop -WarningAction SilentlyContinue}
        $Acl.RemoveAccessRuleAll($rule) | Out-Null
        Set-Acl -Path $path -AclObject $Acl -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
        $Acl.RemoveAccessRule($rule) | Out-Null
        Set-Acl -Path $path -AclObject $Acl -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
        }
    }
