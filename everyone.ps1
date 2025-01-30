# Import the Active Directory module
Import-Module ActiveDirectory

# Define the output file path
$OutputFile = "C:\Temp\EveryonePermissionsReport.txt"

# Function to check permissions for the "Everyone" group in AD
function Check-EveryonePermissions {
    param (
        [string]$SearchBase
    )

    # Get all AD objects in the specified search base
    $ADObjects = Get-ADObject -Filter * -SearchBase $SearchBase -Properties DistinguishedName, nTSecurityDescriptor

    foreach ($Object in $ADObjects) {
        # Get the security descriptor (ACL) for the object
        $ACL = $Object.nTSecurityDescriptor

        # Check if "Everyone" has permissions
        $EveryonePermissions = $ACL.Access | Where-Object { $_.IdentityReference -eq "Everyone" }

        if ($EveryonePermissions) {
            # Write the object details to the output file
            Add-Content -Path $OutputFile -Value "`nObject: $($Object.DistinguishedName)"
            Add-Content -Path $OutputFile -Value "Permissions for 'Everyone':"
            foreach ($Permission in $EveryonePermissions) {
                Add-Content -Path $OutputFile -Value "- Access Rights: $($Permission.AccessRights)"
                Add-Content -Path $OutputFile -Value "- Inheritance: $($Permission.IsInherited)"
                Add-Content -Path $OutputFile -Value "- Inheritance Type: $($Permission.InheritanceType)"
                Add-Content -Path $OutputFile -Value "- Propagation Flags: $($Permission.PropagationFlags)"
                Add-Content -Path $OutputFile -Value "- Access Control Type: $($Permission.AccessControlType)`n"
            }
        }
    }
}

# Main script execution
Write-Host "Checking 'Everyone' permissions in Active Directory..." -ForegroundColor Green

# Clear the output file if it already exists
if (Test-Path $OutputFile) {
    Clear-Content -Path $OutputFile
}

# Specify the search base (e.g., the root of the domain or a specific OU)
$SearchBase = (Get-ADDomain).DistinguishedName

# Check AD object permissions
Check-EveryonePermissions -SearchBase $SearchBase

Write-Host "Script execution completed. Results saved to $OutputFile." -ForegroundColor Green