Import-Module ActiveDirectory

$groups = Get-ADGroup -Filter * -Properties Description | ForEach-Object {
    $ou = ($_.DistinguishedName -split ',') -match '^OU='
    $ouPath = ($ou -join '/').Replace('OU=', '')

    [PSCustomObject]@{
        Name         = $_.Name
        Beschreibung = $_.Description
        Ort          = $ouPath
    }
}

$groups | Export-Csv -Path "C:\Temp\Gruppen_mit_OU.csv" -NoTypeInformation -Encoding UTF8