#! /usr/bin/pwsh
<#
.SYNOPSIS
    Adds a local guest user to Aruba Clearpass
.DESCRIPTION
    This script requires NETCONF and RESTCONF enabled on your controller, and a user with privilege 15.
    See: https://www.cisco.com/c/en/us/td/docs/wireless/controller/technotes/8-8/b_c9800_programmability_telemetry_dg.html

    With this script you can add a local guest user to your Aruba Clearpass installation.

    Password for the guest user will be automatically generated with a length of 10 characters and consists of uppercase, lowercase and numbers.
    You can edit the line
    $GuestPass = New-Password -length 10 -Uppercase -LowerCase -Numeric
    if you want to add complexity.
    For example: $GuestPass = New-Password -length 20 -Uppercase -LowerCase -Numeric -Symbolic
    would create a password like 'jCd(e-$oQ+.H0T,E*8fh'

.NOTES
    Author: Michael Reiner
    Date:   May 05, 2022

    Tested with Aruba Clearpass 6.9.7
#>

Param(
    #Aruba Clearpass IP or Hostname
    [Parameter(Mandatory = $True)]
    #[ValidateScript({ $_ -match [IPAddress]$_ })]
    [string]$IP,

    #API Username
    [Parameter(Mandatory = $True)]
    [string]$User,
    
    #API Password
    [Parameter(Mandatory = $True)]
    [string]$Pass,    

    #Guest Username
    [Parameter(Mandatory = $True)]
    [string]$GuestUser,

    #Guest User Description
    [Parameter(Mandatory = $True)]
    [string]$GuestDesc,

    #User Lifetime in Days
    [Parameter(Mandatory = $True)]
    #[ValidateRange(1,3)]
    [int]$GuestLifeTimeDays
)

Function New-Password { 
 
    [CmdletBinding()] 
    [OutputType([String])] 
 
     
    Param( 
 
        [int]$length = 30, 
 
        [alias("U")] 
        [Switch]$Uppercase, 
 
        [alias("L")] 
        [Switch]$LowerCase, 
 
        [alias("N")] 
        [Switch]$Numeric, 
 
        [alias("S")] 
        [Switch]$Symbolic 
 
    ) 
 
    Begin {} 
 
    Process { 
         
        If ($Uppercase) { $CharPool += ([char[]](64..90)) } 
        If ($LowerCase) { $CharPool += ([char[]](97..122)) } 
        If ($Numeric) { $CharPool += ([char[]](48..57)) } 
        If ($Symbolic) {
            $CharPool += ([char[]](33..47)) 
            $CharPool += ([char[]](33..47))
        } 
         
        If ($CharPool -eq $null) { 
            Throw 'You must select at least one of the parameters "Uppercase" "LowerCase" "Numeric" or "Symbolic"' 
        } 
 
        [String]$Password = (Get-Random -InputObject $CharPool -Count $length) -join '' 
 
    } 
     
    End { 
         
        return $Password 
     
    } 
}

Function Get-AccessToken {
    $baseurl = "https://$IP/api/oauth"

    $header = @{
        "Accept"       = "application/json"
        "Content-Type" = "application/json"
    }
    $body = @"
    {
        "grant_type":"client_credentials", 
        "client_id":"$User", 
        "client_secret":"$Pass"
    }
"@    
    $RestError = $null
    try {
        $AccessToken = Invoke-RestMethod -Method POST -Uri $baseurl -Headers $header -Body $body -ErrorAction Continue
        return $AccessToken
    }
    catch {
        $RestError = $_
    }
}

$GuestPass = New-Password -length 10 -Uppercase -LowerCase -Numeric

$AccessToken = (Get-AccessToken).access_token

if ($AccessToken) {
    $baseurl = "https://$IP/api/guest"
    #$EpochStart = Get-Date -UFormat %s
    $DateEnd = (Get-Date).AddDays($GuestLifeTimeDays)
    $EpochEnd = Get-Date $DateEnd -UFormat %s

    $header = @{
        "Accept"        = "application/json"
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $AccessToken"
    }
    $body = @"
    {
        "enabled":true,
        "notes": "$GuestDesc", 
        "expire_time": "$EpochEnd", 
        "username": "$GuestUser",
        "password": "$GuestPass", 
        "role_id": 2
    }
"@   

    $RestError = $null
    try {
        $Result = Invoke-RestMethod -Method POST -Uri $baseurl -Headers $header -Body $body -ErrorAction Continue
        return $Result
    }
    catch {
        $RestError = $_
        Write-Host $RestError
    }

}
