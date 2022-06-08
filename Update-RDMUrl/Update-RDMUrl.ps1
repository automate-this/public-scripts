#! /usr/bin/pwsh
<#
.SYNOPSIS
    Gets all RDP, SSH and Web Connections from Devolutions Password Server SQL Database and writes them via REST API to checkMK 
.DESCRIPTION
    This script requires the Powershell-Module "SQLServer"
    Install-Module -Name SQLServer

    Database User needs SELECT permissions on tables "DatabaseInfo" and "Connections"

.NOTES
    Author: Michael Reiner
    Date:   June 08, 2022
#>

Param(
    #DPS Database Server and Instance
    [Parameter(Mandatory = $True)]
    [string]$DPSDBServer
    ,
    #DPS Database Name
    [Parameter(Mandatory = $True)]
    [string]$DPSDBName,

    #DPS Database Credentials
    [Parameter(Mandatory = $True)]
    [pscredential]$DPSDBCred,

    #CheckMK Server
    [Parameter(Mandatory = $True)]
    [string]$CMKServer,

    #CheckMK Site Name
    [Parameter(Mandatory = $True)]
    [string]$CMKSite,

    #CheckMK API User
    [Parameter(Mandatory = $True)]
    [string]$CMKUser,

    #CheckMK API Password
    [Parameter(Mandatory = $True)]
    [securestring]$CMKPass
)

function Get-Connections {
    $query = @"
    DECLARE @dbid nvarchar(MAX)
    set @dbid  = (SELECT CAST(Settings AS xml).value('(/DataSourceSettings/DBID)[1]', 'VARCHAR(MAX)') FROM DatabaseInfo)
    SELECT Name AS title, ('rdm://open?DataSource=' + @dbid + 
        '&Repository=' + CONVERT(nvarchar(36),RepositoryID) + 
        '&Session=' + CONVERT(nvarchar(36),ID)) AS RDMUrl 
        FROM Connections 
        WHERE ConnectionType IN (1,5,77)
"@

    $dbsplat = @{
        ServerInstance = $DPSDBServer
        Database       = $DPSDBName
        Credential     = $DPSDBCred
        Query          = $query
    }
    #$RDMUrls = Invoke-Sqlcmd @dbsplat
    Return Invoke-Sqlcmd @dbsplat
}
function Get-CMKHosts {
    $Pass = ConvertFrom-SecureString $CMKPass -AsPlainText
    $headers = @{}
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer $CMKUser $Pass")

    $reqUrl = "$CMKAPISite/domain-types/host_config/collections/all"

    $response = Invoke-RestMethod -Uri $reqUrl -Method Get -Headers $headers  

    Return $response.value
}
function Get-CMKHostDetails([string]$id){
    $Pass = ConvertFrom-SecureString $CMKPass -AsPlainText
    $headers = @{}
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer $CMKUser $Pass")

    $reqUrl = "$CMKAPISite/objects/host_config/$id"

    $response = Invoke-RestMethod -Uri $reqUrl -Method Get -Headers $headers -ResponseHeadersVariable respheader
    $cmkrdm = $response.extensions.attributes.RDMUrl
    $etag = $respheader["ETag"][0]

    Return $etag, $cmkrdm
}
function Update-CMKHost([string]$id,[string]$etag,[string]$rdmurl){
    $Pass = ConvertFrom-SecureString $CMKPass -AsPlainText
    $headers = @{}
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Bearer $CMKUser $Pass")
    $headers.Add("If-Match", $etag)
    $body = @{
        "update_attributes" = @{
            "RDMUrl"=$rdmurl
        }
    }

    $reqUrl = "$CMKAPISite/objects/host_config/$id"

    $response = Invoke-RestMethod -Uri $reqUrl -Method Put -Headers $headers -Body ($body | ConvertTo-Json)

    #Return $response.value
}

function Activate-CMKChanges {
    $Pass = ConvertFrom-SecureString $CMKPass -AsPlainText
    $headers = @{}
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Bearer $CMKUser $Pass")

    $reqUrl = "$CMKAPISite/domain-types/activation_run/actions/activate-changes/invoke"

    $response = Invoke-RestMethod -Uri $reqUrl -Method Post -Headers $headers
    
}

$CMKAPISite = "https://$CMKServer/$CMKSite/check_mk/api/1.0"

$RDMUrls = Get-Connections
$CMKHosts = Get-CMKHosts

$HostsWithUrls = Compare-Object $RDMUrls -Property "title" -DifferenceObject $CMKHosts -ExcludeDifferent -IncludeEqual -PassThru

# Foreach-Object {
#     [PSCustomObject]@{
#         ID     = $_.ID
#         title  = $_.title
#         etag   = ""
#         RDMUrl = ($RDMUrls | Where-Object title -eq $_.title).RDMUrl
#     }
# }

foreach ($CMKHost in $HostsWithUrls) {
    $id = ($CMKHosts | Where-Object title -eq $CMKHost.title).ID
    $etag, $cmkrdm = Get-CMKHostDetails -id $id
    if ($CMKHost.RDMUrl -ne $cmkrdm) {
        Update-CMKHost -id $id -etag $etag -rdmurl $CMKHost.RDMUrl
    }
    #Update-CMKHost -id $CMKHost.ID -etag (Get-CMKHostDetails($CMKHost.ID)) -rdmurl $CMKHost.RDMUrl
}
Activate-CMKChanges
