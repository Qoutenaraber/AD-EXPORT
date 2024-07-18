# Ensure necessary assembly is loaded
Add-Type -AssemblyName System.Windows.Forms

# Create an OpenFileDialog instance
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog

# Set the initial directory to the current script location
$openFileDialog.InitialDirectory = (Get-Location).Path
$openFileDialog.Filter = "7-Zip Files (*.7z)|*.7z"
$openFileDialog.Title = "Select a 7-Zip file to unpack"

# Show the OpenFileDialog and get the selected file
$dialogResult = $openFileDialog.ShowDialog()

if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedFile = $openFileDialog.FileName
    $outputDirectory = [System.IO.Path]::GetDirectoryName($selectedFile)

    # Define the path to 7z.exe
    $sevenZipPath = "C:\Program Files\7-Zip\7z.exe"

    # Check if 7-Zip is installed
    if (-Not (Test-Path $sevenZipPath)) {
        [System.Windows.Forms.MessageBox]::Show("7-Zip is not installed. Please install 7-Zip and try again.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit
    }

    # Define the command to unpack the selected .7z file
    $unpackCommand = "& `"$sevenZipPath`" x `"$selectedFile`" -o`"$outputDirectory`" -y"

    # Execute the command
    Invoke-Expression $unpackCommand

    # Find the extracted file (assuming there's only one file extracted)
    $extractedFiles = Get-ChildItem -Path $outputDirectory -Filter "*.evtx"
    if ($extractedFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No .evtx file found in the archive.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit
    } elseif ($extractedFiles.Count -gt 1) {
        [System.Windows.Forms.MessageBox]::Show("Multiple .evtx files found. Only the first one will be opened.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }

    $extractedFile = $extractedFiles[0].FullName

    # Open the extracted file in Event Viewer
    Start-Process -FilePath "eventvwr.exe" -ArgumentList "/c:$extractedFile"

    # Notify the user that the extraction is complete and the file is opened
    [System.Windows.Forms.MessageBox]::Show("Extraction complete! The file is opened in Event Viewer.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
} else {
    [System.Windows.Forms.MessageBox]::Show("No file selected.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}