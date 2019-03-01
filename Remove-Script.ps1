$install_location = "$env:userprofile\AppData\Local\POSHTools\Verify-ACH\Application"
$application_folder = "$env:userprofile\AppData\Local\POSHTools\Verify-ACH"
$shortcut_name = "ACH Verify Tool.lnk"
$shortcut_location = $env:USERPROFILE + "\Desktop"
$startmenu_location = $env:userprofile + "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\ACH Tools"

$message = 'Keep Configuration'
$question = 'Do you wish to keep config files?'

$choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

$decision = $Host.UI.PromptForChoice($message, $question, $choices, 0)
switch ($decision)
{
    0 {
        # if choice is yes, remove application, keep config files
        Write-Output "Removing application from: $install_location"
        Remove-Item -Path $install_location -Recurse -Force
    }
    1 {
        # if choice is no, remove application and config files
        Write-Output "Removing application from: $application_folder"
        Remove-Item -Path $application_folder -Recurse -Force
    }
}

Write-Output "Removing start menu shortcut: $startmenu_location"
Remove-Item -Path $startmenu_location -Recurse -Force

Write-Output "Removing desktop shortcut: $shortcut_location\$shortcut_name"
Remove-Item -Path "$shortcut_location\$shortcut_name" -force