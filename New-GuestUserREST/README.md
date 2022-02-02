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