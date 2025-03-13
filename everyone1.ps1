$exportPath = "$env:USERPROFILE\Desktop\Everyone_Permissions.txt"

Get-ADObject -Filter * -Properties nTSecurityDescriptor | 
ForEach-Object {
    $obj = $_.DistinguishedName
    $permissions = $_.nTSecurityDescriptor.Access | Where-Object { $_.IdentityReference -like "*Everyone*" }
    if ($permissions) {
        foreach ($perm in $permissions) {
            [PSCustomObject]@{
                Object = $obj
                Identity = $perm.IdentityReference
                Permissions = $perm.AccessControlType
                Rights = $perm.ActiveDirectoryRights
            }
        }
    }
} | Format-Table -AutoSize | Out-File -Encoding UTF8 $exportPath

Write-Host "Export abgeschlossen! Datei gespeichert unter: $exportPath"