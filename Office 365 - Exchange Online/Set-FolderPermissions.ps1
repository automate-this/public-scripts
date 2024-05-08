#Reset Permissions

$targetmailbox=<Mailbox>
ForEach($f in (Get-MailboxFolderStatistics $targetmailbox | Where { $_.FolderPath.StartsWith("/Posteingang")})) {
 $fname = $targetmailbox + ":" + $f.FolderPath.Replace("/","\");
 $userlistArray = @()
 #Purge existing permsissions and set defaults
 ForEach($g in (Get-MailboxFolderPermission $fname | select User,AccessRights)) {
 if ($g.User.DisplayName -like "Standard" -Or $g.User.DisplayName -like "Anonym" -Or $g.User.DisplayName -like "Anonymous") {
   Set-MailboxFolderPermission $fname -User $g.User.DisplayName -AccessRights None
  }
  else {
   Remove-MailboxFolderPermission $fname -User $g.User.DisplayName -confirm: $false
  }
 }
 #Set owner permissions (modify users and rights to assign other permission values to specific users)
 $user=(<User1>,<User2>,<User3>)
 ForEach ($targetuser in $user){
  Add-MailboxFolderPermission $fname -User $targetuser -AccessRights PublishingEditor
 }
}
