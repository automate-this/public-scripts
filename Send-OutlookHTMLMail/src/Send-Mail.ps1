if(([System.Diagnostics.Process]::GetProcessesByName("OUTLOOK")).length -gt 0)
{
    Write-Host "Outlook is already running!"
    $Outlook = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application")
}
else
{
    Write-Host "Outlook is not running. Creating new process..."
    $Outlook = New-Object -comObject Outlook.Application
}
if ($args.Count -gt 0) {
    $namespace = $Outlook.GetNamespace("MAPI")
    $Mail = $Outlook.CreateItem(0)
    $Subject = Split-Path $args[0] -Leaf
    $Mail.subject = $Subject
    #$Mail.body = ""
    foreach ($file in $args) {
        $Mail.Attachments.Add($file)
    }
    $Mail.Display()
    #$inspector = $Mail.GetInspector
    #$inspector.Activate()
    #Remove-Variable $Outlook, $namespace, $Mail, $inspector
}
#pause
