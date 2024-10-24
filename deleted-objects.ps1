# Step 1: Define the domain and gMSA variables
$domain = "yourdomain.com"  # Replace with your domain name (e.g., contoso.com)
$gMSA = "DOMAIN\gMSAName$"  # Replace with your gMSA name (include $ at the end)

# Step 2: Retrieve the Deleted Objects container using its distinguished name
$deletedObjectsDn = "CN=Deleted Objects,CN=Configuration,DC=yourdomain,DC=com"  # Adjust domain accordingly

# Step 3: Get the current ACL (Access Control List) for the Deleted Objects container
$acl = Get-ACL -Path "LDAP://$deletedObjectsDn"

# Step 4: Create a new access rule for the gMSA to grant ReadProperty (read access)
$permission = "ReadProperty"  # You can add additional permissions if necessary
$accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($gMSA, $permission, "Allow")

# Step 5: Add the new access rule to the current ACL
$acl.AddAccessRule($accessRule)

# Step 6: Apply the modified ACL back to the Deleted Objects container
Set-Acl -Path "LDAP://$deletedObjectsDn" -AclObject $acl

# Step 7: Verify the changes by displaying the updated ACL
Get-Acl -Path "LDAP://$deletedObjectsDn" | Format-List