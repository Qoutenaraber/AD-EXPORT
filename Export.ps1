# Define output directory
$outputDir = "C:\ADInfo"

# Ensure output directory exists
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Function to initialize CSV files with headers
function Initialize-CSV {
    param (
        [string]$filePath,
        [array]$headers
    )
    $nullData = [PSCustomObject]@{}
    foreach ($header in $headers) {
        $nullData | Add-Member -MemberType NoteProperty -Name $header -Value $null
    }
    $nullData | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
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

# Function to log warnings
function Log-Warning {
    param (
        [string]$message
    )
    Write-Warning $message
}

# Function to collect and export AD information
function Export-ADInfo {
    param (
        [string]$outputDir
    )

    # Initialize CSV files with headers
    Initialize-CSV -filePath (Join-Path $outputDir "DomainInformation.csv") -headers @("Category", "Name", "Value")
    Initialize-CSV -filePath (Join-Path $outputDir "Users.csv") -headers @("DisplayName", "SamAccountName", "EmailAddress", "Department", "Title")
    Initialize-CSV -filePath (Join-Path $outputDir "Groups.csv") -headers @("Name", "GroupScope", "GroupCategory", "Description")
    Initialize-CSV -filePath (Join-Path $outputDir "GroupMemberships.csv") -headers @("GroupName", "UserName", "MemberType")
    Initialize-CSV -filePath (Join-Path $outputDir "GroupMembershipErrors.csv") -headers @("GroupName", "Error")
    Initialize-CSV -filePath (Join-Path $outputDir "OrganizationalUnits.csv") -headers @("Name", "DistinguishedName")
    Initialize-CSV -filePath (Join-Path $outputDir "DomainControllers.csv") -headers @("Name", "Site", "IPv4Address", "OperatingSystem")
    Initialize-CSV -filePath (Join-Path $outputDir "Sites.csv") -headers @("Name")
    Initialize-CSV -filePath (Join-Path $outputDir "Subnets.csv") -headers @("Name", "Site")
    Initialize-CSV -filePath (Join-Path $outputDir "GPOs.csv") -headers @("DisplayName", "Id")
    Initialize-CSV -filePath (Join-Path $outputDir "GPOLinks.csv") -headers @("GpoName", "Link")
    Initialize-CSV -filePath (Join-Path $outputDir "FSMORoles.csv") -headers @("Category", "Name", "Value")

    # Collect Domain Information
    Write-Host "Collecting Domain Information..."
    try {
        $domain = Get-ADDomain
        $domainInfo = [PSCustomObject]@{
            Category = "Domain Information"
            Name     = $domain.DNSRoot
            Value    = $null
        }
        Add-ToCSV -filePath (Join-Path $outputDir "DomainInformation.csv") -data $domainInfo
    } catch {
        Log-Warning "Failed to collect Domain Information: $_"
    }

    # Collect Users
    Write-Host "Collecting Users..."
    try {
        $userFilePath = Join-Path $outputDir "Users.csv"
        $users = Get-ADUser -Filter * -Property DisplayName, SamAccountName, EmailAddress, Department, Title
        $userData = $users | Select-Object DisplayName, SamAccountName, EmailAddress, Department, Title
        Add-ToCSV -filePath $userFilePath -data $userData
    } catch {
        Log-Warning "Failed to collect Users: $_"
    }

    # Collect Groups
    Write-Host "Collecting Groups..."
    try {
        $groupFilePath = Join-Path $outputDir "Groups.csv"
        $groups = Get-ADGroup -Filter * -Property Name, GroupScope, GroupCategory, Description
        $groupData = $groups | Select-Object Name, GroupScope, GroupCategory, Description
        Add-ToCSV -filePath $groupFilePath -data $groupData
    } catch {
        Log-Warning "Failed to collect Groups: $_"
    }

    # Collect Group Memberships and log errors
    Write-Host "Collecting Group Memberships..."
    try {
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
    } catch {
        Log-Warning "Failed to collect Group Memberships: $_"
    }

    # Collect Organizational Units
    Write-Host "Collecting Organizational Units..."
    try {
        $ouFilePath = Join-Path $outputDir "OrganizationalUnits.csv"
        $ous = Get-ADOrganizationalUnit -Filter * -Property Name, DistinguishedName
        $ouData = $ous | Select-Object Name, DistinguishedName
        Add-ToCSV -filePath $ouFilePath -data $ouData
    } catch {
        Log-Warning "Failed to collect Organizational Units: $_"
    }

    # Collect Domain Controllers
    Write-Host "Collecting Domain Controllers..."
    try {
        $dcFilePath = Join-Path $outputDir "DomainControllers.csv"
        $dcs = Get-ADDomainController -Filter * -Property Name, Site, IPv4Address, OperatingSystem
        $dcData = $dcs | Select-Object Name, Site, IPv4Address, OperatingSystem
        Add-ToCSV -filePath $dcFilePath -data $dcData
    } catch {
        Log-Warning "Failed to collect Domain Controllers: $_"
    }

    # Collect Sites
    Write-Host "Collecting Sites..."
    try {
        $siteFilePath = Join-Path $outputDir "Sites.csv"
        $sites = Get-ADReplicationSite -Filter * -Property Name
        $siteData = $sites | Select-Object Name
        Add-ToCSV -filePath $siteFilePath -data $siteData
    } catch {
        Log-Warning "Failed to collect Sites: $_"
    }

    # Collect Subnets
    Write-Host "Collecting Subnets..."
    try {
        $subnetFilePath = Join-Path $outputDir "Subnets.csv"
        $subnets = Get-ADReplicationSubnet -Filter * -Property Name, Site
        $subnetData = $subnets | Select-Object Name, Site
        Add-ToCSV -filePath $subnetFilePath -data $subnetData
    } catch {
        Log-Warning "Failed to collect Subnets: $_"
    }

    # Collect GPOs
    Write-Host "Collecting GPOs..."
    try {
        $gpoFilePath = Join-Path $outputDir "GPOs.csv"
        $gpos = Get-GPO -All | Select-Object DisplayName, Id
        Add-ToCSV -filePath $gpoFilePath -data $gpos
    } catch {
        Log-Warning "Failed to collect GPOs: $_"
    }

    # Collect GPO Links
    Write-Host "Collecting GPO Links..."
    try {
        $gpoLinkFilePath = Join-Path $outputDir "GPOLinks.csv"
        foreach ($gpo in $gpos) {
            try {
                $gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
                $xml = [xml]$gpoReport
                $gpoLinks = $xml.SelectNodes("//gpoLinksTo") | ForEach-Object {
                    [PSCustomObject]@{
                        GpoName = $_.displayName
                        Link    = $_.path
                    }
                }
                Add-ToCSV -filePath $gpoLinkFilePath -data $gpoLinks
            } catch {
                $errorInfo = [PSCustomObject]@{
                    GpoName = $gpo.DisplayName
                    Error   = $_.Exception.Message
                }
                Add-ToCSV -filePath $groupMembershipErrorsFilePath -data $errorInfo
}
}
} catch {
Log-Warning “Failed to collect GPO Links: $_”
}
# Collect FSMO Roles
Write-Host "Collecting FSMO Roles..."
try {
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
} catch {
    Log-Warning "Failed to collect FSMO Roles: $_"
}

# Display completion message
Write-Host "Data collection complete. CSV files saved to $outputDir"