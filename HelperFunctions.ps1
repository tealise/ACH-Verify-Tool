<#
.SYNOPSIS
    Expand the console output to a width of a determined [int] value

.PARAMETER Width
    The width as [int] to expand the console window
#>
Function Expand-WindowSize {
    param([int]$Width)  
    if ( $Host -and $Host.UI -and $Host.UI.RawUI ) {
        $rawUI = $Host.UI.RawUI
        $oldSize = $rawUI.BufferSize
        $typeName = $oldSize.GetType().FullName
        $newSize = New-Object $typeName ($Width, $oldSize.Height)
        $rawUI.BufferSize = $newSize
    }
}

# FUNCTIONS FOR VERBOSITY
Function Add-Warning ($message) { Write-Output "*** $message ***"}
Function Add-Log ($message) { Write-Output "[$(Get-Date -Format "MM/dd/yy @ hh:mm:ss")] $message`r`n"}
Function Add-Break { Write-Output "`r`n" }
Function Add-LineBreak { Write-Output ("`r`n") ('*' * 225) ('*' * 225) ("`r`n") }

Function Get-FileName {
    param($initialDirectory)
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "ACH (*.ach)| *.ach|Plain Text (*.txt)| *.txt|All files (*.*)| *.*"
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true })) | Out-Null
    $OpenFileDialog.FileName
}

Function Set-FileName {
    param($initialDirectory)
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.Filter = "ACH (*.ach)| *.ach|Plain Text (*.txt)| *.txt|All files (*.*)| *.*"
    $SaveFileDialog.InitialDirectory = $initialDirectory

    if ($SaveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
    { $SaveFileDialog.FileName }
}

Function Get-Folder {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $FolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog

    if ($FolderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
    { $FolderDialog.SelectedPath }
}

Function ExportACH ($records, $output_path, $output_name_scheme) {
    $records | Out-File -FilePath "$output_path\$($output_name_scheme + $(date).ToString('yyyyMMdd_hhmmss')).ach" -encoding ascii
}

Function ExportCSV ($records, $output_path, $output_name_scheme) {
    $records.GetEnumerator() | Sort-Object Name | Export-CSV "$output_path\$($output_name_scheme + $(date).ToString('yyyyMMdd_hhmmss')).csv" -nti
}

Function Set-ACHRecordContents ($achval) { $script:current_ach_value = $achval }
Function Set-ACHRecordDetailContents ($achval) { $script:current_ach_details = $achval }

Function Show-CurrentACHLine {
    param($record_details,$line)
    
    Add-Log "Before changes, initial line value:"
    # $initial_line = Get-ACHLine $record_details
    
    Add-Log "Read record as:"
    Write-Output ('-'*94)  $line  ('-'*94)
    
    $record_details | ft -property * -autosize
}

Function Show-NewACHLine {
    param($record_details)
    
    $rewritten_line = Get-ACHLine $record_details
    
    Add-Break
    Add-Log "Replaced record with line:"
    Write-Output ('-'*94)  $rewritten_line  ('-'*94)
    
    $record_details | ft -property * -autosize
}

Function Get-ACHLine {
    param($record)
    $ach_record = ''
    $record[0].psobject.properties | select -expand name | %{
        $key = $_
        $value = $record.$_
        if ($nacha_field_definitions.$key.type -eq 'numeric') {
            $ach_record += $(Format-Numeric $value $nacha_field_definitions.$key.'length')
        } elseif ($nacha_field_definitions.$key.type -eq 'numeric_right') {
            $ach_record += $(Format-NumericRight $value $nacha_field_definitions.$key.'length')
        } elseif ($nacha_field_definitions.$key.type -eq 'numeric_dollar') {
            $ach_record += $(Format-NumericDollar $value $nacha_field_definitions.$key.'length')
        } elseif ($nacha_field_definitions.$key.type -eq 'alphanumeric') {
            $ach_record += $(Format-AlphaNumeric $value $nacha_field_definitions.$key.'length')
        } elseif ($nacha_field_definitions.$key.type -eq 'blank') {
            $ach_record += $(Format-Blank $value $nacha_field_definitions.$key.'length')
        }
    }
    $ach_record
}

############ CONFIG FILE HANDLING ############
Function Copy-SettingsToSystem {
	if (!(Test-Path -Path ".\PreviousParameters.xml")) {
		Write-Warning "Unable to copy 'PreviousParameters.xml', file does not exist. Please run 'Get-SettingsFile' to generate config."
		break
	}

    $application_path = "$env:userprofile\AppData\Local\POSHTools\Verify-ACH\config"
    $config_path = $application_path + '\PreviousParameters.xml'
	if (-Not (Test-Path -Path $application_path)) { New-Item -Path $application_path -ItemType Directory | Out-Null }
	Copy-Item ".\PreviousParameters.xml" $config_path
	return "File(s) copied."
}

Function Get-SettingsFile {
	$application_path = "$env:userprofile\AppData\Local\POSHTools\Verify-ACH\config"
    $config_path = $application_path + '\PreviousParameters.xml'

    if (Test-Path -Path $config_path) {
        Get-Content $config_path
    } else {
        Copy-SettingsToSystem
        Get-Content $config_path
    }

}

<#
Function Update-PreviousSettingsXML {
    param($UpdateSettings)

	[xml]$ConfigFile = Get-SettingsFile
    $application_path = "$env:userprofile\AppData\Local\POSHTools\Verify-ACH\config"
    $config_path = $application_path + '\PreviousParameters.xml'

    # FILE SETTINGS
    $ConfigFile.Settings.Files.Input = Set-NullString $UpdateSettings.Files.Input
    $ConfigFile.Settings.Files.Output = Set-NullString $UpdateSettings.Files.Output
    $ConfigFile.Settings.Files.Patch = '1'
    $ConfigFile.Settings.Files.Logging = 'Full'

    # ACH CONTROL SETTINGS
    # Originator 
    $ConfigFile.Settings.ACH.Origin.Routing = Set-NullString $UpdateSettings.ACH.Origin.Routing
    $ConfigFile.Settings.ACH.Origin.Name = Set-NullString $UpdateSettings.ACH.Origin.Name
    $ConfigFile.Settings.ACH.Origin.DFI = Set-NullString $UpdateSettings.ACH.Origin.DFI

    # Destination
    $ConfigFile.Settings.ACH.Destination.Routing = Set-NullString $UpdateSettings.ACH.Destination.Routing
    $ConfigFile.Settings.ACH.Destination.Name = Set-NullString $UpdateSettings.ACH.Destination.Name

    # SAVE FILE
	$ConfigFile.Save($config_path) | Out-Null

	return $ConfigFile
}
#>

Function Set-NullString {
    param($string)

    if ($string) { $string } else { '' }
}