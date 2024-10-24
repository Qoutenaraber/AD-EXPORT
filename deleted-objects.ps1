# Ensure you are running this script as a Domain Admin or an account with sufficient privileges.

# Step 1: Define the Domain and gMSA variables
$domain = "yourdomain.com"  # Replace with your domain name (e.g., contoso.com)
$gMSA = "DOMAIN\gMSAName$"  # Replace with your gMSA name (include $ at the end)

# Step 2: Retrieve the Deleted Objects container
$deletedObjects = Get-ADObject -Filter {name -eq "Deleted Objects"} -IncludeDeletedObjects

# Step 3: Get the current Access Control List (ACL) for the Deleted Objects container
$acl = Get-Acl -Path "AD:\CN=Deleted Objects,DC=yourdomain,DC=com"

# Step 4: Create a new access rule for the gMSA to grant ReadProperty (read access)
$permission = "ReadProperty"  # You can add additional permissions if necessary
$accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($gMSA, $permission, "Allow")

# Step 5: Add the new access rule to the current ACL
$acl.AddAccessRule($accessRule)

# Step 6: Apply the modified ACL back to the Deleted Objects container
Set-Acl -Path "AD:\CN=Deleted Objects,DC=yourdomain,DC=com" -AclObject $acl

# Step 7: Verify the changes by displaying the updated ACL
Get-Acl -Path "AD:\CN=Deleted Objects,DC=yourdomain,DC=com" | Format-List