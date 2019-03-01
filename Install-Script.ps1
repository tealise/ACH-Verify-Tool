$install_location = "$env:userprofile\AppData\Local\POSHTools\Verify-ACH\Application"
$config_location = "$env:userprofile\AppData\Local\POSHTools\Verify-ACH\config"
$shortcut_name = "ACH Verify Tool.lnk"
$shortcut_location = $env:USERPROFILE + "\Desktop"
$startmenu_location = $env:userprofile + "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\ACH Tools"
$original_location = "$(Split-Path -Parent $PSCommandPath)\"

Write-Output "Install location: $install_location"

# Remove previous version if installed
if (Test-Path -Path $install_location) {
    Write-Output "Removing previous version"
    Remove-Item -Path $install_location -Recurse -Force
}

# Copy application files to AppData
Write-Output "Installing new version"
Copy-Item -Path $original_location -Destination $install_location -recurse -force
if (-not (Test-Path $config_location)) {
    New-Item -ItemType Directory -Force -Path $config_location | Out-Null
}

# Remove the install files, but keep the uninstall/remove scripts
Write-Output "Cleaning up install files"
Remove-Item -Path "$install_location\install*.*"
    
Function New-Shortcut {
    param($Location,$ShortcutName)
    Write-Output "Creating shortcut: $Location\$ShortcutName"

    if (-not (Test-Path $Location)) {
        New-Item -ItemType Directory -Force -Path $Location | Out-Null
    }
    if (-not (Test-Path "$Location\$ShortcutName")) {
        $Shell = New-Object -ComObject ("WScript.Shell")
        $ShortCut = $Shell.CreateShortcut("$Location\$ShortcutName")
        $ShortCut.TargetPath = "$install_location\Verify-ACH.bat"
        $ShortCut.WorkingDirectory = $install_location;
        $ShortCut.WindowStyle = 1;
        $ShortCut.IconLocation = "$install_location\img\bank-icon.ico, 0";
        $ShortCut.Description = "ACH Verification and Patching Tool";
        $ShortCut.Save()
    }
}

# Create desktop and start menu shortcuts
New-Shortcut -Location $shortcut_location -ShortcutName $shortcut_name
New-Shortcut -Location $startmenu_location -ShortcutName $shortcut_name

# Open application
& "$install_location\Verify-ACH.bat"