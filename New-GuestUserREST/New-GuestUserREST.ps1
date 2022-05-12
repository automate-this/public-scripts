#! /usr/bin/pwsh
<#
.SYNOPSIS
    Adds a local guest user to your Cisco 9800 WLC via RESTCONF
.DESCRIPTION
    This script requires NETCONF and RESTCONF enabled on your controller, and a user with privilege 15.
    See: https://www.cisco.com/c/en/us/td/docs/wireless/controller/technotes/8-8/b_c9800_programmability_telemetry_dg.html

    With this script you can add a local guest user to your Cisco Wireless Lan Controller.

    Password for the guest user will be automatically generated with a length of 10 characters and consists of uppercase, lowercase and numbers.
    You can edit the line
    $GuestPass = New-Password -length 10 -Uppercase -LowerCase -Numeric
    if you want to add complexity.
    For example: $GuestPass = New-Password -length 20 -Uppercase -LowerCase -Numeric -Symbolic
    would create a password like 'jCd(e-$oQ+.H0T,E*8fh'

.NOTES
    Author: Michael Reiner
    Date:   February 02, 2022

    Tested with Cisco 9800 virtual controller
#>

Param(
    #Cisco Wireless Lan Controller IP
    [Parameter(Mandatory=$True)]
    [ValidateScript({$_ -match [IPAddress]$_ })]
    [string]$IP,

    #RESTCONF Username
    [Parameter(Mandatory=$True)]
    [string]$User,
    
    #RESTCONF Password
    [Parameter(Mandatory=$True)]
    [string]$Pass,    

    #Guest Username
    [Parameter(Mandatory=$True)]
    [string]$GuestUser,

    #Guest User Description
    [Parameter(Mandatory=$True)]
    [string]$GuestDesc,

    #User Lifetime in Days
    [Parameter(Mandatory=$True)]
    #[ValidateRange(1,3)]
    [int]$GuestLifeTimeDays
)

Function New-Password { 
 
    [CmdletBinding()] 
    [OutputType([String])] 
 
     
    Param( 
 
        [int]$length=30, 
 
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
         
        If ($Uppercase) {$CharPool += ([char[]](64..90))} 
        If ($LowerCase) {$CharPool += ([char[]](97..122))} 
        If ($Numeric) {$CharPool += ([char[]](48..57))} 
        If ($Symbolic) {$CharPool += ([char[]](33..47)) 
                       $CharPool += ([char[]](33..47))} 
         
        If ($CharPool -eq $null) { 
            Throw 'You must select at least one of the parameters "Uppercase" "LowerCase" "Numeric" or "Symbolic"' 
        } 
 
        [String]$Password =  (Get-Random -InputObject $CharPool -Count $length) -join '' 
 
    } 
     
    End { 
         
        return $Password 
     
    } 
}

$baseurl = "https://$IP/restconf/data/Cisco-IOS-XE-native:native/user-name"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $User,$Pass)))

$GuestPass = New-Password -length 10 -Uppercase -LowerCase -Numeric

$header = @{
    "Authorization"="Basic $base64AuthInfo"
    "Accept"="application/yang-data+json"
    "Content-Type"="application/yang-data+json"
}
$RestError = $null
try {
    $Users = Invoke-RestMethod -Method GET -Uri "$baseurl=$GuestUser" -Headers $header -ErrorAction Continue
}
catch {
    $RestError = $_
}

if (!$RestError -and !$Users) {
        $body = @"
    {
        "user-name": [
            {
            "name": "$GuestUser",
            "type": {
                "network-user": {
                    "description": "$GuestDesc",
                    "guest-user": {
                        "max-login-limit": 0,
                        "lifetime": {
                        "year": 0,
                        "month": 0,
                        "day": $GuestLifeTimeDays,
                        "hour": 0,
                        "minute": 0,
                        "second": 0
                        }
                    }
                }
            },
            "password": {
                "password": "$GuestPass"
            }
            }
        ]
        }
"@
    try {
        Invoke-RestMethod -Method PATCH -Uri $baseurl -Headers $header -Body $body
    }
    catch {
        $RestError = $_
    }
    
}
else {
    if ($Users) {
        write-host 'Username already exists!' -ForegroundColor Red
    }
    $RestError
}
