# Verzeichnis, in dem die Logs gespeichert sind
$sourceDir = "C:\Logs"
# Zielverzeichnis für die sortierten Logs
$targetDir = "C:\Logs\Sorted"

# Hole das heutige Datum
$currentDate = Get-Date

# Erstelle das Verzeichnis für das aktuelle Jahr (yyyy) und den Monat (MM als Zahl)
$yearDir = Join-Path $targetDir $currentDate.ToString("yyyy")
$monthDir = Join-Path $yearDir $currentDate.ToString("MM")

# Erstelle die Verzeichnisse, falls sie nicht existieren
if (-not (Test-Path $yearDir)) {
    New-Item -Path $yearDir -ItemType Directory
}
if (-not (Test-Path $monthDir)) {
    New-Item -Path $monthDir -ItemType Directory
}

# Hole alle .7z-Dateien aus dem Quellverzeichnis, die dem Muster dd-MM-yyyy_Security.7z entsprechen
$files = Get-ChildItem -Path $sourceDir -Filter "*_Security.7z" | Where-Object {
    # Überprüfe, ob der Dateiname dem Muster dd-MM-yyyy_Security.7z entspricht
    if ($_ -match "^(\d{2})-(\d{2})-(\d{4})_Security.7z$") {
        $fileDate = [datetime]::ParseExact($matches[0], "dd-MM-yyyy_Security.7z", $null)
        return $fileDate -ge (Get-Date).AddDays(-1)
    }
}

# Verschiebe jede Datei in den entsprechenden Monatsordner
foreach ($file in $files) {
    $destinationPath = Join-Path $monthDir $file.Name
    Move-Item -Path $file.FullName -Destination $destinationPath
}