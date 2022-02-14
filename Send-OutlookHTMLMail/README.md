# Summary

The install.ps1 places the Send-Mail.ps1 in %LocalAppData% and a shortcut to "shell:sendto".

After running install.ps1 you have a new entry in "Windows Explorer -> Send To".
You can now select multiple files in Explorer, send to -> "Mit Outlook senden", and it opens a new Outlook HTML Mail
with the selected files attached.

I wrote this script because the default "send to -> mail recipient" still to this day creates a PLAIN TEXT mail instead of HTML. This causes a bunch of issues for example with HTML signatures.