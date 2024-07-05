# Define output directory
$outputDir = "C:\ADInfo"

# Ensure output directory exists
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Function to add entries to CSV and initialize CSV files
function Add-ToCSV {
    param (
        [string]$filePath,
        [array]$data,
        [array]$headers = @()
    )
    if ($headers -ne $null -and (Test-Path $filePath) -eq $false) {
        $nullData = [PSCustomObject]@{}
        foreach ($header in $headers) { $nullData | Add-Member -MemberType NoteProperty -Name $header -Value $null }
        $nullData | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
    }
    if ($data) { $data | Export-Csv -Path $filePath -Append -NoTypeInformation -Encoding UTF8 }
}

# Initialize CSV files with headers
$files = @{
    "DomainInformation.csv"    = @("Category", "Name", "Value")
    "Users.csv"                = @("DisplayName", "SamAccountName", "EmailAddress", "Department", "Title")
    "Groups.csv"               = @("Name", "GroupScope", "GroupCategory", "Description")
    "GroupMemberships.csv"     = @("GroupName", "UserName", "MemberType")
    "GroupMembershipErrors.csv"= @("GroupName", "Error")
    "OrganizationalUnits.csv"  = @("Name", "DistinguishedName")
    "DomainControllers.csv"    = @("Name", "Site", "IPv4Address", "OperatingSystem")
    "Sites.csv"                = @("Name")
    "Subnets.csv"              = @("Name", "Site")
    "GPOs.csv"                 = @("DisplayName", "Id")
    "GPOLinks.csv"             = @("GpoName", "Link")
    "FSMORoles.csv"            = @("Category", "Name", "Value")
}
$files.GetEnumerator() | ForEach-Object { Add-ToCSV -filePath (Join-Path $outputDir $_.Key) -data $null -headers $_.Value }

# Collect and export AD information
try {
    $domain = Get-ADDomain
    Add-ToCSV -filePath (Join-Path $outputDir "DomainInformation.csv") -data @([PSCustomObject]@{Category="Domain Information"; Name=$domain.DNSRoot; Value=$null})

    $users = Get-ADUser -Filter * -Property DisplayName, SamAccountName, EmailAddress, Department, Title | Select-Object DisplayName, SamAccountName, EmailAddress, Department, Title
    Add-ToCSV -filePath (Join-Path $outputDir "Users.csv") -data $users

    $groups = Get-ADGroup -Filter * -Property Name, GroupScope, GroupCategory, Description | Select-Object Name, GroupScope, GroupCategory, Description
    Add-ToCSV -filePath (Join-Path $outputDir "Groups.csv") -data $groups

    # Fix for the problematic part: Group Memberships and Errors
foreach ($group in $groups) {
    try {
        $members = Get-ADGroupMember -Identity $group.Name -ErrorAction Stop
        foreach ($member in $members) {
            $membershipObject = [PSCustomObject]@{
                GroupName = $group.Name
                UserName = $member.SamAccountName
                MemberType = $member.objectClass
            }
            Add-ToCSV -filePath (Join-Path $outputDir "GroupMemberships.csv") -data @($membershipObject)
        }
    } catch {
        $errorObject = [PSCustomObject]@{
            GroupName = $group.Name
            Error = $_.Exception.Message
        }
        Add-ToCSV -filePath (Join-Path $outputDir "GroupMembershipErrors.csv") -data @($errorObject)
    }
}
    $ous = Get-ADOrganizationalUnit -Filter * -Property Name, DistinguishedName | Select-Object Name, DistinguishedName
    Add-ToCSV -filePath (Join-Path $outputDir "OrganizationalUnits.csv") -data $ous

    $dcs = Get-ADDomainController -Filter * | Select-Object Name, Site, IPv4Address, OperatingSystem
    Add-ToCSV -filePath (Join-Path $outputDir "DomainControllers.csv") -data $dcs

    $sites = Get-ADReplicationSite -Filter * -Property Name | Select-Object Name
    Add-ToCSV -filePath (Join-Path $outputDir "Sites.csv") -data $sites

    $subnets = Get-ADReplicationSubnet -Filter * -Property Name, Site | Select-Object Name, Site
    Add-ToCSV -filePath (Join-Path $outputDir "Subnets.csv") -data $subnets

    $gpos = Get-GPO -All | Select-Object DisplayName, Id
    Add-ToCSV -filePath (Join-Path $outputDir "GPOs.csv") -data $gpos

    # Fix for the problematic part: GPOLinks
$gpoLinks = @()
$gpoLinkErrors = @()

foreach ($gpo in $gpos) {
    try {
        $gpoReport = Get-GPOReport -Guid $gpo.Id -ReportType Xml
        $xml = [xml]$gpoReport
        $links = $xml.GPO.LinksTo | ForEach-Object {
            [PSCustomObject]@{
                GpoName = $gpo.DisplayName
                Link = $_.Target
            }
        }
        $gpoLinks += $links
    } catch {
        $gpoLinkErrors += [PSCustomObject]@{
            GpoName = $gpo.DisplayName
            Error = $_.Exception.Message
        }
    }
}

Add-ToCSV -filePath (Join-Path $outputDir "GPOLinks.csv") -data $gpoLinks
Add-ToCSV -filePath (Join-Path $outputDir "GpoLinkErrors.csv") -data $gpoLinkErrors

    $forest = Get-ADForest
    $fsmoRoles = @()
    foreach ($role in @("InfrastructureMaster", "PDCEmulator", "RIDMaster")) {
        $fsmoRoles += [PSCustomObject]@{Category="FSMO Roles"; Name=$role; Value=$domain.$role}
    }
    foreach ($role in @("DomainNamingMaster", "SchemaMaster")) {
        $fsmoRoles += [PSCustomObject]@{Category="FSMO Roles"; Name=$role; Value=$forest.$role}
    }
    Add-ToCSV -filePath (Join-Path $outputDir "FSMORoles.csv") -data $fsmoRoles

} catch {
    Write-Warning "Failed to collect some data: $_"
}

Write-Host "Data collection complete. CSV files saved to $outputDir"