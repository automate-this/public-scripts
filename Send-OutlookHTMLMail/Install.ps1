Copy-Item -Path "$PSScriptRoot\src\Mit Outlook senden.lnk" -Destination "$env:AppData\Microsoft\Windows\SendTo" -Force
Copy-Item -Path "$PSScriptRoot\src\Send-Mail.ps1" -Destination $env:LocalAppData -Force
