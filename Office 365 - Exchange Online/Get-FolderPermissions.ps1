$targetmailbox = <Mailbox>
ForEach($f in (Get-MailboxFolderStatistics $targetmailbox | Where {$_.FolderPath.StartsWith("/Posteingang")})) {
 $fname = $targetmailbox + ":" + $f.FolderPath.Replace("/","\");
 write-host $fname -BackgroundColor "Green" -ForegroundColor "Black"
 $userlistArray = @()
 ForEach($g in (Get-MailboxFolderPermission $fname | select User,AccessRights)){
 if ($g.User -like "Standard" -Or $g.User -like "Anonym") {
   write-host " " $g.User ":" $g.AccessRights -BackgroundColor "White" -ForegroundColor "Black"
  }
 else {
   write-host " " $g.User ":" $g.AccessRights
  }
 }
}
