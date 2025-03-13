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