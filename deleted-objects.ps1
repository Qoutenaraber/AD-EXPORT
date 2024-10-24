# Step 1: Define your domain and gMSA
$domain = "yourdomain.com"  # Replace with your domain name (e.g., contoso.com)
$gMSA = "DOMAIN\gMSAName$"  # Replace with your gMSA name (include $ at the end)

# Step 2: Bind to the Deleted Objects container using [ADSI]
$deletedObjectsDn = "LDAP://CN=Deleted Objects,DC=yourdomain,DC=com"  # Adjust domain accordingly
$deletedObjects = [ADSI]$deletedObjectsDn

# Step 3: Get the current ACL (Access Control List) for the Deleted Objects container
$acl = $deletedObjects.psbase.ObjectSecurity

# Step 4: Create a new access rule for the gMSA to grant ReadProperty and ListContents
$identity = New-Object System.Security.Principal.NTAccount($gMSA)

# Combine ReadProperty and ListContents permissions
$permission = [System.DirectoryServices.ActiveDirectoryRights]::ReadProperty -bor `
              [System.DirectoryServices.ActiveDirectoryRights]::ListContents

# Inheritance to apply permissions to all child objects
$inheritance = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All

# Create the access rule
$accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
    $identity, 
    $permission, 
    "Allow", 
    $inheritance
)

# Step 5: Add the new access rule to the current ACL
$acl.AddAccessRule($accessRule)

# Step 6: Apply the modified ACL back to the Deleted Objects container
$deletedObjects.psbase.ObjectSecurity = $acl
$deletedObjects.CommitChanges()

# Step 7: Verify the changes by retrieving and displaying the updated ACL
$updatedAcl = $deletedObjects.psbase.ObjectSecurity
$updatedAcl