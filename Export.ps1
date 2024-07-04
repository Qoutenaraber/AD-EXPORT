# Define output directory
$outputDir = "C:\ADInfo"

# Ensure output directory exists
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Function to add entries to CSV
function Add-ToCSV {
    param (
        [string]$filePath,
        [string]$category,
        [string]$name,
        [string]$value
    )
    $entry = [PSCustomObject]@{
        Category = $category
        Name     = $name
        Value    = $value
    }
    $entry | Export-Csv -Path $filePath -Append -NoTypeInformation -Encoding UTF8
}

# Function to collect and export AD information
function Export-ADInfo {
    param (
        [string]$outputDir
    )

    # Helper function to handle repetitive tasks
    function Collect-Data {
        param (
            [scriptblock]$dataCommand,
            [string]$fileName,
            [string]$category,
            [scriptblock]$nameExpression,
            [scriptblock]$valueExpression
        )
        $filePath = Join-Path $outputDir $fileName
        & $dataCommand | ForEach-Object {
            Add-ToCSV -filePath $filePath -category $category -name (& $nameExpression $_) -value (& $valueExpression $_)
        }
    }

    # Collect Domain Information
    $domain = Get-ADDomain
    Add-ToCSV -filePath (Join-Path $outputDir "DomainInformation.csv") -category "Domain Information" -name $domain.DNSRoot -value $null

    # Collect Users in batches
    $userProperties = 'Name', 'DistinguishedName', 'EmailAddress', 'Department', 'Title'
    $batchSize = 100
    $skip = 0
    $userFilePath = Join-Path $outputDir "Users.csv"
    do {
        $users = Get-ADUser -Filter * -Property $userProperties -ResultSetSize $batchSize -SearchScope Subtree -Skip $skip
        $users | ForEach-Object {
            Add-ToCSV -filePath $userFilePath -category "Users" -name $_.Name -value "DN: $($_.DistinguishedName), Email: $($_.EmailAddress), Dept: $($_.Department), Title: $($_.Title)"
        }
        $skip += $batchSize
    } while ($users.Count -eq $batchSize)

    # Collect Groups in batches
    $groupProperties = 'Name', 'GroupScope', 'GroupCategory'
    $skip = 0
    $groupFilePath = Join-Path $outputDir "Groups.csv"
    do {
        $groups = Get-ADGroup -Filter * -Property $groupProperties -ResultSetSize $batchSize -SearchScope Subtree -Skip $skip
        $groups | ForEach-Object {
            Add-ToCSV -filePath $groupFilePath -category "Groups" -name $_.Name -value "Scope: $($_.GroupScope), Category: $($_.GroupCategory)"
        }
        $skip += $batchSize
    } while ($groups.Count -eq $batchSize)

    # Collect Group Memberships including nested groups
    $groupMembershipFilePath = Join-Path $outputDir "GroupMemberships.csv"
    $groups = Get-ADGroup -Filter * -Property Name
    foreach ($group in $groups) {
        $members = Get-ADGroupMember -Identity $group.Name
        $members | ForEach-Object {
            Add-ToCSV -filePath $groupMembershipFilePath -category "Group Memberships" -name $_.Name -value "Member of: $($group.Name)"
            if ($_.objectClass -eq 'group') {
                Add-ToCSV -filePath $groupMembershipFilePath -category "Group Memberships" -name $_.Name -value "Group Member of: $($group.Name)"
            }
        }
    }

    # Collect Organizational Units
    Collect-Data {
        Get-ADOrganizationalUnit -Filter * | Select-Object -Property Name, DistinguishedName
    } "OrganizationalUnits.csv" "Organizational Units" {
        $_.Name
    } {
        $_.DistinguishedName
    }

    # Collect Domain Controllers
    Collect-Data {
        Get-ADDomainController -Filter * | Select-Object -Property Name, Site, IPv4Address, OperatingSystem
    } "DomainControllers.csv" "Domain Controllers" {
        $_.Name
    } {
        "Site: $($_.Site), IP: $($_.IPv4Address), OS: $($_.OperatingSystem)"
    }

    # Collect Sites
    Collect-Data {
        Get-ADReplicationSite -Filter * | Select-Object -Property Name
    } "Sites.csv" "Sites" {
        $_.Name
    } {
        $null
    }

    # Collect Subnets
    Collect-Data {
        Get-ADReplicationSubnet -Filter * | Select-Object -Property Name, Site
    } "Subnets.csv" "Subnets" {
        $_.Name
    } {
        $_.Site
    }

    # Collect GPOs
    Collect-Data {
        Get-GPO -All | Select-Object -Property DisplayName, Id
    } "GPOs.csv" "GPOs" {
        $_.DisplayName
    } {
        $_.Id
    }

    # Collect GPO Links
    Collect-Data {
        Get-GPO -All | ForEach-Object {
            Get-GPOReport -Guid $_.Id -ReportType Xml | Select-Xml -XPath "//gpoLinksTo" | ForEach-Object {
                [PSCustomObject]@{GpoName = $_.Node.SelectSingleNode("displayName").InnerText; Link = $_.Node.SelectSingleNode("path").InnerText}
            }
        }
    } "GPOLinks.csv" "GPO Links" {
        $_.GpoName
    } {
        $_.Link
    }

    # Collect FSMO Roles
    $forest = Get-ADForest
    $fsmoRolesFilePath = Join-Path $outputDir "FSMORoles.csv"
    foreach ($role in @("InfrastructureMaster", "PDCEmulator", "RIDMaster")) {
        Add-ToCSV -filePath $fsmoRolesFilePath -category "FSMO Roles" -name $role -value $domain.$role
    }
    foreach ($role in @("DomainNamingMaster", "SchemaMaster")) {
        Add-ToCSV -filePath $fsmoRolesFilePath -category "FSMO Roles" -name $role -value $forest.$role
    }

    # Display completion message
    Write-Host "Data collection complete. CSV files saved to $outputDir"
}

# Execute function to export AD information
Export-ADInfo -outputDir $outputDir
