#Reset Permissions
cls
$targetmailbox=<MailBox>
ForEach($f in (Get-MailboxFolderStatistics $targetmailbox | Where { $_.FolderPath.StartsWith("/Posteingang")})) {
 $fname = $targetmailbox + ":" + $f.FolderPath.Replace("/","\");
 $userlistArray = @()
 #Purge existing permsissions and set defaults
 ForEach($g in (Get-MailboxFolderPermission $fname | select User,AccessRights)) {
 if ($g.User -like "Standard") {
   Set-MailboxFolderPermission $fname -User $g.User -AccessRights None
  }
  else {
   Remove-MailboxFolderPermission $fname -User $g.User -confirm: $false
  }
 }
 #Set owner permissions (modify users and rights to assign other permission values to specific users)
 $user=(<User1>,<User2>,<User3>)
 ForEach ($targetuser in $user){
  Add-MailboxFolderPermission $fname -User $targetuser -AccessRights Owner
 }
}
