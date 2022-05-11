## SYNOPSIS
Adds a local guest user to Aruba Clearpass

## DESCRIPTION

With this script you can add a local guest user to your Aruba Clearpass installation.

Password for the guest user will be automatically generated with a length of 10 characters and consists of uppercase, lowercase and numbers.
You can edit the line
$GuestPass = New-Password -length 10 -Uppercase -LowerCase -Numeric
if you want to add complexity.
For example: $GuestPass = New-Password -length 20 -Uppercase -LowerCase -Numeric -Symbolic
would create a password like 'jCd(e-$oQ+.H0T,E*8fh'

## NOTES
Author: Michael Reiner
Date:   May 05, 2022

Tested with Aruba Clearpass 6.9.7