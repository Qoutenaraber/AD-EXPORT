# Import the Active Directory module
Import-Module ActiveDirectory

# Define the output file path (in the same directory as the script)
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputFile = Join-Path -Path $ScriptDirectory -ChildPath "EveryonePermissions_FirstLevelOUs.txt"

# Function to check permissions for the "Everyone" group in first-level OUs
function Check-EveryonePermissionsInFirstLevelOUs {
    param (
        [string]$SearchBase
    )

    # Get all first-level OUs in the specified search base
    $FirstLevelOUs = Get-ADOrganizationalUnit -Filter * -SearchBase $SearchBase -SearchScope OneLevel -Properties DistinguishedName, nTSecurityDescriptor

    foreach ($OU in $FirstLevelOUs) {
        # Get the security descriptor (ACL) for the OU
        $ACL = $OU.nTSecurityDescriptor

        # Check if "Everyone" has permissions
        $EveryonePermissions = $ACL.Access | Where-Object { $_.IdentityReference -eq "Everyone" }

        if ($EveryonePermissions) {
            # Write the OU details to the output file
            Add-Content -Path $OutputFile -Value "`nOU: $($OU.DistinguishedName)"
            Add-Content -Path $OutputFile -Value "Permissions for 'Everyone':"
            foreach ($Permission in $EveryonePermissions) {
                Add-Content -Path $OutputFile -Value "- Access Rights: $($Permission.AccessRights)"
                Add-Content -Path $OutputFile -Value "- Inheritance: $($Permission.IsInherited)"
                Add-Content -Path $OutputFile -Value "- Inheritance Type: $($Permission.InheritanceType)"
                Add-Content -Path $OutputFile -Value "- Propagation Flags: $($Permission.PropagationFlags)"
                Add-Content -Path $OutputFile -Value "- Access Control Type: $($Permission.AccessControlType)`n"
            }
        } else {
            Add-Content -Path $OutputFile -Value "`nOU: $($OU.DistinguishedName)"
            Add-Content -Path $OutputFile -Value "No permissions for 'Everyone' found."
        }
    }
}

# Main script execution
Write-Host "Checking 'Everyone' permissions in first-level OUs..." -ForegroundColor Green

# Clear the output file if it already exists
if (Test-Path $OutputFile) {
    Clear-Content -Path $OutputFile
}

# Specify the search base (root of the domain)
$SearchBase = (Get-ADDomain).DistinguishedName

# Check permissions in first-level OUs
Check-EveryonePermissionsInFirstLevelOUs -SearchBase $SearchBase

Write-Host "Script execution completed. Results saved to $OutputFile." -ForegroundColor Green