# Import the Active Directory module
Import-Module ActiveDirectory

# Define the output file path (in the same directory as the script)
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputFile = Join-Path -Path $ScriptDirectory -ChildPath "EveryonePermissions_FullAD.txt"

# Function to decode Access Rights
function Decode-AccessRights {
    param (
        [int]$AccessMask
    )
    $AccessRights = @()
    if ($AccessMask -band 0x1) { $AccessRights += "ReadProperty" }
    if ($AccessMask -band 0x2) { $AccessRights += "WriteProperty" }
    if ($AccessMask -band 0x4) { $AccessRights += "CreateChild" }
    if ($AccessMask -band 0x8) { $AccessRights += "DeleteChild" }
    if ($AccessMask -band 0x10) { $AccessRights += "ListChildren" }
    if ($AccessMask -band 0x20) { $AccessRights += "Self" }
    if ($AccessMask -band 0x40) { $AccessRights += "DeleteTree" }
    if ($AccessMask -band 0x80) { $AccessRights += "ListObject" }
    if ($AccessMask -band 0x100) { $AccessRights += "ExtendedRight" }
    if ($AccessMask -band 0x200) { $AccessRights += "Delete" }
    if ($AccessMask -band 0x400) { $AccessRights += "ReadControl" }
    if ($AccessMask -band 0x800) { $AccessRights += "WriteDacl" }
    if ($AccessMask -band 0x1000) { $AccessRights += "WriteOwner" }
    if ($AccessMask -band 0x10000) { $AccessRights += "Synchronize" }
    if ($AccessMask -band 0x100000) { $AccessRights += "FullControl" }
    return $AccessRights -join ", "
}

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
            foreach ($Permission in $EveryonePermissions) {
                # Decode Access Rights
                $AccessRights = Decode-AccessRights -AccessMask $Permission.AccessMask

                # Only write output if Access Rights are not empty
                if ($AccessRights) {
                    Add-Content -Path $OutputFile -Value "`nObject: $($Object.DistinguishedName)"
                    Add-Content -Path $OutputFile -Value "Permissions for 'Everyone':"
                    Add-Content -Path $OutputFile -Value "- Access Rights: $AccessRights"
                    Add-Content -Path $OutputFile -Value "- Inheritance: $($Permission.IsInherited)"
                    Add-Content -Path $OutputFile -Value "- Inheritance Type: $($Permission.InheritanceType)"
                    Add-Content -Path $OutputFile -Value "- Propagation Flags: $($Permission.PropagationFlags)"
                    Add-Content -Path $OutputFile -Value "- Access Control Type: $($Permission.AccessControlType)`n"
                }
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

# Specify the search base (root of the domain)
$SearchBase = (Get-ADDomain).DistinguishedName

# Check AD object permissions
Check-EveryonePermissions -SearchBase $SearchBase

Write-Host "Script execution completed. Results saved to $OutputFile." -ForegroundColor Green