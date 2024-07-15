# Import Active Directory module
Import-Module ActiveDirectory

# Define the group and description filter
$groupName = "domainadmins"
$descriptionFilter = "Exchange"

# Get all users in the specified group
$usersInGroup = Get-ADGroupMember -Identity $groupName -Recursive | Where-Object { $_.objectClass -eq 'user' }

# Initialize an array to store filtered users
$filteredUsers = @()

# Filter users by description
foreach ($user in $usersInGroup) {
    $userDetails = Get-ADUser -Identity $user -Properties Description
    if ($userDetails.Description -like "*$descriptionFilter*") {
        $filteredUsers += $userDetails
    }
}

# Export the filtered users to a CSV file
$filteredUsers | Select-Object SamAccountName, Name, Description | Export-Csv -Path "C:\Path\To\Export\FilteredUsers.csv" -NoTypeInformation

Write-Output "Export completed. The CSV file is located at C:\Path\To\Export\FilteredUsers.csv"