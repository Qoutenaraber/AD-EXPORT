$exportPath = "$env:USERPROFILE\Desktop\Everyone_Permissions.txt"

# Datei vorher leeren/falls vorhanden löschen
if (Test-Path $exportPath) { Remove-Item $exportPath }

# Header in die Datei schreiben
"Object;Identity;Permissions;Rights" | Out-File -Encoding UTF8 $exportPath

# AD durchsuchen
Get-ADObject -Filter * -Properties nTSecurityDescriptor | ForEach-Object {
    $obj = $_.DistinguishedName
    $permissions = $_.nTSecurityDescriptor.Access | Where-Object { $_.IdentityReference -match "Everyone" }
    
    if ($permissions) {
        foreach ($perm in $permissions) {
            "$obj;Everyone;$($perm.AccessControlType);$($perm.ActiveDirectoryRights)" | Out-File -Append -Encoding UTF8 $exportPath
        }
    }
}

Write-Host "Export abgeschlossen! Datei gespeichert unter: $exportPath"