# Definiere den Ordner, in dem die Protokolle gespeichert werden
$logFolder = "C:\EventLogs"
$errorLogFile = Join-Path -Path $logFolder -ChildPath "ErrorLog.txt"

# E-Mail-Konfiguration
$smtpServer = "smtp.example.com"
$smtpFrom = "admin@example.com"
$smtpTo = "alert@example.com"
$emailSubject = "Fehler beim Exportieren des Sicherheitsprotokolls"
$emailBody = "Ein Fehler ist beim Exportieren des Sicherheitsprotokolls aufgetreten. Details im Anhang."

try {
    # Erstelle den Ordner, falls er nicht existiert
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory
    }

    # Hole das aktuelle Datum und die aktuelle Uhrzeit
    $currentDate = Get-Date
    $logFileName = $currentDate.ToString("yyyy-MM-dd") + "_Security.evtx"

    # Definiere den Pfad für die Protokolldatei
    $logFilePath = Join-Path -Path $logFolder -ChildPath $logFileName

    # Definiere die Startzeit für die Filterung der Protokolle (letzte 24 Stunden)
    $startTime = (Get-Date).AddDays(-1)

    # Hole die Sicherheitsprotokolle der letzten 24 Stunden
    $events = Get-WinEvent -FilterHashtable @{LogName='Security'; StartTime=$startTime}

    # Exportiere die Protokolle in eine temporäre .evtx-Datei
    $events | Out-File -FilePath "C:\EventLogs\tempLog.xml"

    # Konvertiere die temporäre XML-Protokolldatei in das .evtx-Format
    wevtutil epl "C:\EventLogs\tempLog.xml" $logFilePath

    # Entferne die temporäre XML-Protokolldatei
    Remove-Item "C:\EventLogs\tempLog.xml"
} catch {
    # Logge den Fehler in eine Datei
    $errorMessage = "[$((Get-Date).ToString())] Fehler: $($_.Exception.Message)"
    Add-Content -Path $errorLogFile -Value $errorMessage
    
    # Sende eine E-Mail, wenn ein Fehler auftritt
    # E-Mail-Versand auskommentieren, um ihn zu deaktivieren
    # $message = New-Object system.net.mail.mailmessage
    # $message.from = $smtpFrom
    # $message.To.Add($smtpTo)
    # $message.Subject = $emailSubject
    # $message.Body = $emailBody
    # $attachment = New-Object System.Net.Mail.Attachment($errorLogFile)
    # $message.Attachments.Add($attachment)
    # $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    # $smtp.Send($message)
}