# Define the LDAP path to the Deleted Objects container
$deletedObjectsDn = "LDAP://CN=Deleted Objects,DC=yourdomain,DC=com"  # Adjust domain accordingly

# Bind to the Deleted Objects container
$deletedObjects = [ADSI]$deletedObjectsDn

# Get the current ACL
$acl = $deletedObjects.psbase.ObjectSecurity

# Display the ACL entries
$acl.Access | Format-Table -Property IdentityReference, ActiveDirectoryRights, AccessControlType