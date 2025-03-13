Get-ADOrganizationalUnit -Filter * -Properties nTSecurityDescriptor | 
ForEach-Object {
    $ou = $_.DistinguishedName
    $permissions = $_.nTSecurityDescriptor.Access | Where-Object { $_.IdentityReference -like "*Everyone*" }
    if ($permissions) {
        [PSCustomObject]@{
            OU = $ou
            Permissions = $permissions
        }
    }
}



Get-ADObject -Filter * -Properties nTSecurityDescriptor | 
ForEach-Object {
    $obj = $_.DistinguishedName
    $permissions = $_.nTSecurityDescriptor.Access | Where-Object { $_.IdentityReference -like "*Everyone*" }
    if ($permissions) {
        [PSCustomObject]@{
            Object = $obj
            Permissions = $permissions
        }
    }
}

Get-GPO -All | ForEach-Object {
    $gpo = $_
    $permissions = Get-GPPermission -Guid $gpo.Id -All | Where-Object { $_.Trustee.Name -eq "Everyone" }
    if ($permissions) {
        [PSCustomObject]@{
            GPO = $gpo.DisplayName
            Permissions = $permissions
        }
    }
}