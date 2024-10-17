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
    # Monat als zweistellige Zahl formatieren (z.B. 01, 02, ..., 12)
    $formattedMonth = "{0:D2}" -f $month
    $monthDir = Join-Path $yearDir -ChildPath $formattedMonth

    # Überprüfe, ob der Monatsordner existiert, und erstelle ihn falls nicht
    if (-not (Test-Path $monthDir)) {
        New-Item -Path $monthDir -ItemType Directory
    }
}

# Hole alle .7z-Dateien aus dem Quellverzeichnis, die dem Muster dd-MM-yyyy_Security.7z entsprechen
$files = Get-ChildItem -Path $sourceDir -Filter "*_Security.7z" | Where-Object {
    # Überprüfe, ob der Dateiname dem Muster dd-MM-yyyy_Security.7z entspricht
    if ($_ -match "^(\d{2})-(\d{2})-(\d{4})_Security.7z$") {
        return $true
    } else {
        return $false
    }
}

# Verschiebe jede Datei in den entsprechenden Monatsordner
foreach ($file in $files) {
    # Extrahiere das Datum aus dem Dateinamen mit Regex
    if ($file.Name -match "^(\d{2})-(\d{2})-(\d{4})_Security.7z$") {
        # Extrahiere Tag, Monat und Jahr aus dem Dateinamen
        $day = $matches[1]
        $month = $matches[2]
        $year = $matches[3]

        # Erstelle ein Datumsobjekt aus den extrahierten Teilen
        $fileDate = [datetime]::ParseExact("$day-$month-$year", "dd-MM-yyyy", $null)
        
        # Bestimme das Zielverzeichnis für die Datei (basierend auf dem Jahr und Monat)
        $destinationDir = Join-Path $targetDir -ChildPath "$year\$month"

        # Erstelle das Zielverzeichnis, falls es nicht existiert
        if (-not (Test-Path $destinationDir)) {
            New-Item -Path $destinationDir -ItemType Directory
        }

        # Verschiebe die Datei in das entsprechende Monatsverzeichnis
        $destinationPath = Join-Path $destinationDir $file.Name
        Move-Item -Path $file.FullName -Destination $destinationPath
    }
}