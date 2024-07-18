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

    # Notify the user that the extraction is complete
    [System.Windows.Forms.MessageBox]::Show("Extraction complete!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
} else {
    [System.Windows.Forms.MessageBox]::Show("No file selected.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}