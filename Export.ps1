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
        [object]$data
    )
    if ($data -ne $null -and $data.Count -gt 0) {
        $data | Export-Csv -Path $filePath -Append -NoTypeInformation -Encoding UTF8
    }
}

# Function to collect and export AD information
function Export-ADInfo {
    param (
        [string]$outputDir
    )

    # Collect Domain Information
    $domain = Get-ADDomain
    $domainInfo = [PSCustomObject]@{
        Category = "Domain Information"
        Name     = $domain.DNSRoot
        Value    = $null
    }
    Add-ToCSV -filePath (Join-Path $outputDir "DomainInformation.csv") -data $domainInfo

    # Collect Users
    $userFilePath = Join-Path $outputDir "Users.csv"
    $users = Get-ADUser -Filter * -Property DisplayName, SamAccountName, EmailAddress, Department, Title
    $userData = $users | Select-Object DisplayName, SamAccountName, EmailAddress, Department, Title
    Add-ToCSV -filePath $userFilePath -data $userData

    # Collect Groups
    $groupFilePath = Join-Path $outputDir "Groups.csv"
    $groups = Get-ADGroup -Filter * -Property Name, GroupScope, GroupCategory, Description
    $groupData = $groups | Select-Object Name, GroupScope, GroupCategory, Description
    Add-ToCSV -filePath $groupFilePath -data $groupData

    # Collect Group Memberships and log errors
    $groupMembershipFilePath = Join-Path $outputDir "GroupMemberships.csv"
    $groupMembershipErrorsFilePath = Join-Path $outputDir "GroupMembershipErrors.csv"
    foreach ($group in $groups) {
        try {
            $members = Get-ADGroupMember -Identity $group.Name -ErrorAction Stop
            foreach ($member in $members) {
                $memberInfo = [PSCustomObject]@{
                    GroupName  = $group.Name
                    UserName   = $member.SamAccountName
                    MemberType = $member.objectClass
                }
                Add-ToCSV -filePath $groupMembershipFilePath -data $memberInfo
            }
        } catch {
            $errorInfo = [PSCustomObject]@{
                GroupName = $group.Name
                Error     = $_.Exception.Message
            }
            Add-ToCSV -filePath $groupMembershipErrorsFilePath -data $errorInfo
        }
    }

    # Collect Organizational Units
    $ouFilePath = Join-Path $outputDir "OrganizationalUnits.csv"
    $ous = Get-ADOrganizationalUnit -Filter * -Property Name, DistinguishedName
    $ouData = $ous | Select-Object Name, DistinguishedName
    Add-ToCSV -filePath $ouFilePath -data $ouData

    # Collect Domain Controllers
    $dcFilePath = Join-Path $outputDir "DomainControllers.csv"
    $dcs = Get-ADDomainController -Filter * -Property Name, Site, IPv4Address, OperatingSystem
    $dcData = $dcs | Select-Object Name, Site, IPv4Address, OperatingSystem
    Add-ToCSV -filePath $dcFilePath -data $dcData

    # Collect Sites
    $siteFilePath = Join-Path $outputDir "Sites.csv"
    $sites = Get-ADReplicationSite -Filter * -Property Name
    $siteData = $sites | Select-Object Name
    Add-ToCSV -filePath $siteFilePath -data $siteData

    # Collect Subnets
    $subnetFilePath = Join-Path $outputDir "Subnets.csv"
    $subnets = Get-ADReplicationSubnet -Filter * -Property Name, Site
    $subnetData = $subnets | Select-Object Name, Site
    Add-ToCSV -filePath $subnetFilePath -data $subnetData

    # Collect GPOs
    $gpoFilePath = Join-Path $outputDir "GPOs.csv"
    $gpos = Get-GPO -All | Select-Object DisplayName, Id
    Add-ToCSV -filePath $gpoFilePath -data $gpos

    # Collect GPO Links
    $gpoLinkFilePath = Join-Path $outputDir "GPOLinks.csv"
    foreach ($gpo in $gpos) {
        $gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
        $gpoLinks = $gpoReport | Select-Xml -XPath "//gpoLinksTo" | ForEach-Object {
            [PSCustomObject]@{
                GpoName = $_.Node.SelectSingleNode("displayName").InnerText
                Link    = $_.Node.SelectSingleNode("path").InnerText
            }
        }
        Add-ToCSV -filePath $gpoLinkFilePath -data $gpoLinks
    }

    # Collect FSMO Roles
    $fsmoRolesFilePath = Join-Path $outputDir "FSMORoles.csv"
    $forest = Get-ADForest
    $fsmoRoles = @()
    foreach ($role in @("InfrastructureMaster", "PDCEmulator", "RIDMaster")) {
        $fsmoRoles += [PSCustomObject]@{
            Category = "FSMO Roles"
            Name     = $role
            Value    = $domain.$role
        }
    }
    foreach ($role in @("DomainNamingMaster", "SchemaMaster")) {
        $fsmoRoles += [PSCustomObject]@{
            Category = "FSMO Roles"
            Name     = $role
            Value    = $forest.$role
        }
    }
    Add-ToCSV -filePath $fsmoRolesFilePath -data $fsmoRoles

    # Display completion message
    Write-Host "Data collection complete. CSV files saved to $outputDir"
}

# Execute function to export AD information
Export-ADInfo -outputDir $outputDir