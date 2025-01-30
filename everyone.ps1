# Import the Active Directory module
Import-Module ActiveDirectory

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
            Write-Host "`nObject: $($Object.DistinguishedName)" -ForegroundColor Yellow
            Write-Host "Permissions for 'Everyone':" -ForegroundColor Cyan
            foreach ($Permission in $EveryonePermissions) {
                Write-Host "- Access Rights: $($Permission.AccessRights)"
                Write-Host "- Inheritance: $($Permission.IsInherited)"
                Write-Host "- Inheritance Type: $($Permission.InheritanceType)"
                Write-Host "- Propagation Flags: $($Permission.PropagationFlags)"
                Write-Host "- Access Control Type: $($Permission.AccessControlType)`n"
            }
        }
    }
}

# Main script execution
Write-Host "Checking 'Everyone' permissions in Active Directory..." -ForegroundColor Green

# Specify the search base (e.g., the root of the domain or a specific OU)
$SearchBase = (Get-ADDomain).DistinguishedName

# Check AD object permissions
Check-EveryonePermissions -SearchBase $SearchBase

Write-Host "Script execution completed." -ForegroundColor Green