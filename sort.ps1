# Verzeichnis, in dem die Logs gespeichert sind
$sourceDir = "C:\Logs"
# Zielverzeichnis für die sortierten Logs
$targetDir = "C:\Logs\Sorted"

# Hole das heutige Datum
$currentDate = Get-Date

# Erstelle das Verzeichnis für das aktuelle Jahr (yyyy)
$yearDir = Join-Path $targetDir $currentDate.ToString("yyyy")

# Erstelle das Verzeichnis für das Jahr, falls es nicht existiert
if (-not (Test-Path $yearDir)) {
    New-Item -Path $yearDir -ItemType Directory
}

# Erstelle alle Monatsverzeichnisse (01 bis 12)
for ($month = 1; $month -le 12; $month++) {
    $monthDir = Join-Path $yearDir -ChildPath "{0:D2}" -f $month

    # Überprüfe, ob der Monatsordner existiert, und erstelle ihn falls nicht
    if (-not (Test-Path $monthDir)) {
        New-Item -Path $monthDir -ItemType Directory
    }
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
    $fileDate = [datetime]::ParseExact($file.Name.Substring(0, 10), "dd-MM-yyyy", $null)
    $fileYear = $fileDate.ToString("yyyy")
    $fileMonth = $fileDate.ToString("MM")

    # Bestimme das Zielverzeichnis für die Datei (basierend auf dem Jahr und Monat)
    $destinationDir = Join-Path $targetDir -ChildPath "$fileYear\$fileMonth"
    
    # Verschiebe die Datei in das entsprechende Monatsverzeichnis
    $destinationPath = Join-Path $destinationDir $file.Name
    Move-Item -Path $file.FullName -Destination $destinationPath
}