# Benutzernamen interaktiv abfragen
$userName = Read-Host "Geben Sie den Benutzernamen ein"

# Export-Pfad auf das Skript-Verzeichnis setzen
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$exportPath = Join-Path $scriptPath "OU_Berechtigungen_$userName.csv"

Import-Module ActiveDirectory

# SID des Benutzers ermitteln und in NTAccount übersetzen
$user = Get-ADUser $userName -Properties SID -ErrorAction Stop
$ntAccount = ([System.Security.Principal.SecurityIdentifier]$user.SID).Translate([System.Security.Principal.NTAccount])

# Berechtigungen sammeln
$results = Get-ADOrganizationalUnit -Filter * | ForEach-Object {
    $ou = $_
    Get-Acl "AD:\$($ou.DistinguishedName)" | Select-Object -ExpandProperty Access |
    Where-Object IdentityReference -eq $ntAccount.Value |
    Select-Object @{n="OU";e={$ou.Name}},
                  @{n="Organisationseinheit";e={$ou.DistinguishedName}},
                  IdentityReference,
                  AccessControlType,
                  ActiveDirectoryRights,
                  IsInherited
}

# Export und Ausgabe
$results | Export-Csv $exportPath -NoTypeInformation -Encoding UTF8
Write-Host "Berechtigungen für '$userName' exportiert nach: $exportPath`n"