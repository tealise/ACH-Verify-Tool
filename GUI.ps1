<#
.NAME
    ACH Verification Tool
#>

$current_path = [string]$(Split-Path -Parent $PSCommandPath)
. $current_path\HelperFunctions.ps1
. $current_path\Test-ABA\ABAChecker.ps1 -LoadFunctions

Add-Type -AssemblyName System.Windows.Forms
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
[System.Windows.Forms.Application]::EnableVisualStyles()

$ACHVerificationTool               = New-Object system.Windows.Forms.Form
$ACHVerificationTool.ClientSize    = '1200,725'
$ACHVerificationTool.MinimumSize   = '1210,745'
$ACHVerificationTool.text          = "ACH NACHA Verification Tool"
$ACHVerificationTool.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$ACHVerificationTool.TopMost       = $false
$ACHVerificationTool.MaximizeBox   = $False
$ACHVerificationTool.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$ACHVerificationTool.Icon          = "$(Split-Path -Parent $PSCommandPath)\img\bank-icon.ico"

$Title                           = New-Object system.Windows.Forms.Label
$Title.text                      = "ACH NACHA Verification Tool"
$Title.AutoSize                  = $true
$Title.width                     = 25
$Title.height                    = 10
$Title.location                  = New-Object System.Drawing.Point(25,15)
$Title.Font                      = 'Segoe UI,18'

#region File Input/Output Panel
# Panel definition
$FilePanel                       = New-Object system.Windows.Forms.Groupbox
$FilePanel.height                = 225
$FilePanel.width                 = 360
$FilePanel.text                  = "File Input/Output"
$FilePanel.location              = New-Object System.Drawing.Point(25,65)

# ACH File Input Textbox and Browse handling
$ACHInputFilePathLabel               = New-Object system.Windows.Forms.Label
$ACHInputFilePathLabel.text          = "ACH Input File Path:"
$ACHInputFilePathLabel.AutoSize      = $true
$ACHInputFilePathLabel.width         = 25
$ACHInputFilePathLabel.height        = 10
$ACHInputFilePathLabel.location      = New-Object System.Drawing.Point(15,23)
$ACHInputFilePathLabel.Font          = 'Microsoft Sans Serif,10'

$ACHInputFilePath                = New-Object system.Windows.Forms.TextBox
$ACHInputFilePath.multiline       = $false
$ACHInputFilePath.width           = 250
$ACHInputFilePath.height          = 27
$ACHInputFilePath.location        = New-Object System.Drawing.Point(15,45)
$ACHInputFilePath.Font            = 'Microsoft Sans Serif,11'

$ACHInputFilePathButton          = New-Object system.Windows.Forms.Button
$ACHInputFilePathButton.text     = "Browse"
$ACHInputFilePathButton.width    = 60
$ACHInputFilePathButton.height   = 25
$ACHInputFilePathButton.location = New-Object System.Drawing.Point(285,45)
$ACHInputFilePathButton.Font     = 'Microsoft Sans Serif,10'

# Working directory textbox and browse handling
$WorkingDirectoryLabel           = New-Object system.Windows.Forms.Label
$WorkingDirectoryLabel.text      = "Working Directory:"
$WorkingDirectoryLabel.AutoSize  = $true
$WorkingDirectoryLabel.width     = 25
$WorkingDirectoryLabel.height    = 10
$WorkingDirectoryLabel.location  = New-Object System.Drawing.Point(15,80)
$WorkingDirectoryLabel.Font      = 'Microsoft Sans Serif,10'

$WorkingDirectory                = New-Object system.Windows.Forms.TextBox
$WorkingDirectory.multiline      = $false
$WorkingDirectory.width          = 250
$WorkingDirectory.height         = 26
$WorkingDirectory.location       = New-Object System.Drawing.Point(15,100)
$WorkingDirectory.Font           = 'Microsoft Sans Serif,11'

$WorkingDirectoryButton          = New-Object system.Windows.Forms.Button
$WorkingDirectoryButton.text     = "Browse"
$WorkingDirectoryButton.width    = 60
$WorkingDirectoryButton.height   = 25
$WorkingDirectoryButton.location  = New-Object System.Drawing.Point(285,100)
$WorkingDirectoryButton.Font     = 'Microsoft Sans Serif,10'

#region File Handling

$ACHInputFilePathButton.Add_Click( {
    if ($ACHInputFilePath.Text) {
        if (Test-Path $ACHInputFilePath.Text) {
            $ACHInputFilePath.Text = Get-FileName -InitialDirectory $ACHInputFilePath.Text
        }
    } else {
        $ACHInputFilePath.Text = Get-FileName
    }
})
$ACHInputFilePath.Add_TextChanged( {
    if (-not $ACHInputFilePath.Text) {
        $SuccessProvider.SetError($ACHInputFilePath, "")
        $ErrorProvider.SetError($ACHInputFilePath, "")
    }
    elseif (Test-Path -Path $ACHInputFilePath.Text) {
        $SuccessProvider.SetError($ACHInputFilePath, "OK")
        $ErrorProvider.SetError($ACHInputFilePath, "")
    }
    else {
        $ErrorProvider.SetError($ACHInputFilePath, "Check path, not found or no access")
        $SuccessProvider.SetError($ACHInputFilePath, "")
    }
})
$WorkingDirectoryButton.Add_Click( {
    $WorkingDirectory.Text = Get-Folder
})
$WorkingDirectory.Add_TextChanged( {
    if (-not $WorkingDirectory.Text) {
        $SuccessProvider.SetError($WorkingDirectory, "")
        $ErrorProvider.SetError($WorkingDirectory, "")
    }
    elseif (Test-Path -Path $WorkingDirectory.Text) {
        $SuccessProvider.SetError($WorkingDirectory, "OK")
        $ErrorProvider.SetError($WorkingDirectory, "")
    }
    else {
        $ErrorProvider.SetError($WorkingDirectory, "Check path, not found or no access")
        $SuccessProvider.SetError($WorkingDirectory, "")
    }
})

#endregion

# Tool Options (Patching and Logigng Options)
$PatchFile                       = New-Object system.Windows.Forms.CheckBox
$PatchFile.text                  = "Patch File?"
$PatchFile.AutoSize              = $false
$PatchFile.width                 = 95
$PatchFile.height                = 20
$PatchFile.location              = New-Object System.Drawing.Point(15,145)
$PatchFile.Font                  = 'Microsoft Sans Serif,11'
$PatchFile.Checked               = $true

$LogBasic                        = New-Object system.Windows.Forms.RadioButton
$LogBasic.text                   = "Basic Logging"
$LogBasic.AutoSize               = $true
$LogBasic.width                  = 104
$LogBasic.height                 = 20
$LogBasic.location               = New-Object System.Drawing.Point(125,145)
$LogBasic.Font                   = 'Microsoft Sans Serif,11'

$LogFull                        = New-Object system.Windows.Forms.RadioButton
$LogFull.text                   = "Full Logging"
$LogFull.AutoSize               = $true
$LogFull.width                  = 104
$LogFull.height                 = 20
$LogFull.location               = New-Object System.Drawing.Point(125,170)
$LogFull.Font                   = 'Microsoft Sans Serif,11'
$LogFull.Checked                = $True

$LogNone                        = New-Object system.Windows.Forms.RadioButton
$LogNone.text                   = "No Logging"
$LogNone.AutoSize               = $true
$LogNone.width                  = 104
$LogNone.height                 = 20
$LogNone.location               = New-Object System.Drawing.Point(125,195)
$LogNone.Font                   = 'Microsoft Sans Serif,11'
#endregion

#region ACH Control Settings Panel
$ACHControlSettingsPanel         = New-Object system.Windows.Forms.Groupbox
$ACHControlSettingsPanel.height  = 265
$ACHControlSettingsPanel.width   = 360
$ACHControlSettingsPanel.text    = "ACH Control Settings"
$ACHControlSettingsPanel.location  = New-Object System.Drawing.Point(25,315)

# Immediate Origin
$ImmediateOriginLabel            = New-Object system.Windows.Forms.Label
$ImmediateOriginLabel.text       = "Imm. Origin Routing Number:"
$ImmediateOriginLabel.AutoSize   = $true
$ImmediateOriginLabel.width      = 25
$ImmediateOriginLabel.height     = 10
$ImmediateOriginLabel.location   = New-Object System.Drawing.Point(15,23)
$ImmediateOriginLabel.Font       = 'Microsoft Sans Serif,10'

$ImmediateOrigin                 = New-Object system.Windows.Forms.TextBox
$ImmediateOrigin.multiline       = $false
$ImmediateOrigin.width           = 165
$ImmediateOrigin.height          = 27
$ImmediateOrigin.location        = New-Object System.Drawing.Point(15,45)
$ImmediateOrigin.Font            = 'Microsoft Sans Serif,11'

$ODFILabel            = New-Object system.Windows.Forms.Label
$ODFILabel.text       = "Imm. Origin DFI:"
$ODFILabel.AutoSize   = $true
$ODFILabel.width      = 25
$ODFILabel.height     = 10
$ODFILabel.location   = New-Object System.Drawing.Point(200,23)
$ODFILabel.Font       = 'Microsoft Sans Serif,10'

$ODFI                 = New-Object system.Windows.Forms.TextBox
$ODFI.multiline       = $false
$ODFI.width           = 140
$ODFI.height          = 27
$ODFI.location        = New-Object System.Drawing.Point(200,45)
$ODFI.Font            = 'Microsoft Sans Serif,11'

$ImmediateOriginNameLabel        = New-Object system.Windows.Forms.Label
$ImmediateOriginNameLabel.text   = "Imm. Origin Name:"
$ImmediateOriginNameLabel.AutoSize  = $true
$ImmediateOriginNameLabel.width  = 25
$ImmediateOriginNameLabel.height  = 10
$ImmediateOriginNameLabel.location  = New-Object System.Drawing.Point(15,80)
$ImmediateOriginNameLabel.Font   = 'Microsoft Sans Serif,10'

$ImmediateOriginName             = New-Object system.Windows.Forms.TextBox
$ImmediateOriginName.multiline   = $false
$ImmediateOriginName.width       = 325
$ImmediateOriginName.height      = 27
$ImmediateOriginName.location    = New-Object System.Drawing.Point(15,100)
$ImmediateOriginName.Font        = 'Microsoft Sans Serif,11'

#region Immediate Origin Handlers

$ImmediateOrigin.Add_TextChanged( {
   if ($ImmediateOrigin.Text -match "\d{8}") {
        $result = Test-ABA -RoutingNumber $ImmediateOrigin.Text
        if ($result.code -ne 200) {
            # Invalid
            $ErrorProvider.SetError($ImmediateOrigin, "$($result.code): $($result.message)");
            $SuccessProvider.SetError($ImmediateOrigin, "")
        } else {
            # Valid
            $SuccessProvider.SetError($ImmediateOrigin, $($result.customer_name))
            $ErrorProvider.SetError($ImmediateOrigin, "")
            $ImmediateOriginName.Text = $result.customer_name
            $ODFI.Text = ($result.rn).substring(0,8)
        }
    } else {
        # Invalid
        $ErrorProvider.SetError($ImmediateOrigin, "Please use 9 Digit ABA routing number")
        $SuccessProvider.SetError($ImmediateOrigin, "")
    }

})

#endregion

# Immediate Destination
$ImmediateDestinationLabel       = New-Object system.Windows.Forms.Label
$ImmediateDestinationLabel.text  = "Imm. Destination Routing Number:"
$ImmediateDestinationLabel.AutoSize  = $true
$ImmediateDestinationLabel.width  = 25
$ImmediateDestinationLabel.height  = 10
$ImmediateDestinationLabel.location  = New-Object System.Drawing.Point(15,137)
$ImmediateDestinationLabel.Font  = 'Microsoft Sans Serif,10'

$ImmediateDestination            = New-Object system.Windows.Forms.TextBox
$ImmediateDestination.multiline  = $false
$ImmediateDestination.width      = 325
$ImmediateDestination.height     = 27
$ImmediateDestination.location   = New-Object System.Drawing.Point(15,160)
$ImmediateDestination.Font       = 'Microsoft Sans Serif,11'

$ImmediateDestinationNameLabel   = New-Object system.Windows.Forms.Label
$ImmediateDestinationNameLabel.text  = "Imm. Destination Name:"
$ImmediateDestinationNameLabel.AutoSize  = $true
$ImmediateDestinationNameLabel.width  = 25
$ImmediateDestinationNameLabel.height  = 10
$ImmediateDestinationNameLabel.location  = New-Object System.Drawing.Point(15,197)
$ImmediateDestinationNameLabel.Font  = 'Microsoft Sans Serif,10'

$ImmediateDestinationName        = New-Object system.Windows.Forms.TextBox
$ImmediateDestinationName.multiline  = $false
$ImmediateDestinationName.width  = 325
$ImmediateDestinationName.height  = 27
$ImmediateDestinationName.location  = New-Object System.Drawing.Point(15,220)
$ImmediateDestinationName.Font   = 'Microsoft Sans Serif,11'

#region Immediate Destination Handlers

$ImmediateDestination.Add_TextChanged( {
        if ($ImmediateDestination.Text -match "\d{8}") {
            $result = Test-ABA -RoutingNumber $ImmediateDestination.Text
            if ($result.code -ne 200) {
                # Invalid
                $ErrorProvider.SetError($ImmediateDestination, "$($result.code): $($result.message)");
                $SuccessProvider.SetError($ImmediateDestination, "")
            }
            else {
                # Valid
                $SuccessProvider.SetError($ImmediateDestination, $($result.customer_name))
                $ErrorProvider.SetError($ImmediateDestination, "")
                $ImmediateDestinationName.Text = $result.customer_name
            }
        }
        else {
            # Invalid
            $ErrorProvider.SetError($ImmediateDestination, "Please use 9 Digit ABA routing number");
            $SuccessProvider.SetError($ImmediateDestination, "")
        }

    })

#endregion

#endregion

#region Console Output Objects
$ConsoleOutput = New-Object system.Windows.Forms.TextBox
$ConsoleOutput.Multiline = $true
$ConsoleOutput.ReadOnly = $true
$ConsoleOutput.WordWrap = $false
$ConsoleOutput.ScrollBars = "Vertical"
$ConsoleOutput.width = 785 # 557
$ConsoleOutput.height = 645
$ConsoleOutput.Anchor = 'top,right'
$ConsoleOutput.location = New-Object System.Drawing.Point(400, 15)
$ConsoleOutput.Font = 'Consolas,10'

$ConsoleOutputSelectAllButton = New-Object System.Windows.Forms.Label
$ConsoleOutputSelectAllButton.Text = "Select All"
$ConsoleOutputSelectAllButton.Width = 75 
$ConsoleOutputSelectAllButton.Height = 20
$ConsoleOutputSelectAllButton.location = New-Object System.Drawing.Point(1115, 662)
$ConsoleOutputSelectAllButton.Font = 'Microsoft Sans Serif,11'
$ConsoleOutputSelectAllButton.ForeColor = 'Gray'
$ConsoleOutputSelectAllButton.Add_Click( {
        # Set focus to console output box
        $ConsoleOutput.Focus();
        # Select all text
        $ConsoleOutput.SelectAll()
    })

# Event Handlers for select all button underline style
$ConsoleOutputSelectAllButton.Add_MouseEnter( {
        $ConsoleOutputSelectAllButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 11, [System.Drawing.FontStyle]::Underline)
    })
$ConsoleOutputSelectAllButton.Add_MouseLeave( {
        $ConsoleOutputSelectAllButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 11, [System.Drawing.FontStyle]::Regular)
    })

#endregion

#region Progress Bar Objects
$ProgressLabel                   = New-Object system.Windows.Forms.Label
$ProgressLabel.text              = "Progress"
$ProgressLabel.AutoSize          = $true
$ProgressLabel.width             = 25
$ProgressLabel.height            = 10
$ProgressLabel.location          = New-Object System.Drawing.Point(15,688)
$ProgressLabel.Anchor            = 'left,bottom'
$ProgressLabel.Font              = 'Microsoft Sans Serif,10'

$ProgressBar                     = New-Object system.Windows.Forms.ProgressBar
$ProgressBar.text                = "Progress"
$ProgressBar.width               = 1085
$ProgressBar.height              = 22
$ProgressBar.Anchor              = 'right,bottom'
$ProgressBar.location            = New-Object System.Drawing.Point(98,688)
$ProgressBar.Value               = 0
#endregion

#region Verify and Logfile action buttons
$VerifyButton                     = New-Object system.Windows.Forms.Button
$VerifyButton.text                = "Verify"
$VerifyButton.width               = 170
$VerifyButton.height              = 50
$VerifyButton.location            = New-Object System.Drawing.Point(25,610)
$VerifyButton.Font                = 'Microsoft Sans Serif,10'

$VerifyButton.Add_Click({
    if (-not $ACHInputFilePath.Text) {
        $ErrorProvider.SetError($ACHInputFilePath, "Field required")
        $SuccessProvider.SetError($ACHInputFilePath, "")
    } else {
        $verifyACHParams = @{
            ACHFileName = $ACHInputFilePath.Text
            OutputFolder = $WorkingDirectory.Text
            FileHeader  = @{
                immediate_destination      = $ImmediateDestination.Text
                immediate_destination_name = $ImmediateDestinationName.Text
                immediate_origin           = $ImmediateOrigin.Text
                immediate_origin_name      = $ImmediateOriginName.Text
            }
            RunFromGUI = $true
        }
        if ($PatchFile.Checked) {
            $verifyACHParams.Patch = $True  
        }
        $verifyACHParams
        .\Verify-ACH.ps1 @verifyACHParams
        $ach_file_object = Get-ChildItem $ACHInputFilePath.Text | Select *
        $ConsoleOutput.Lines = (Get-Content $([string]$WorkingDirectory.Text + '\' + [string]$ach_file_object.basename + '_Fixed.ach'))
        $ShowLogfileButton.Enabled = $true
        $ProgressBar.Value = 0
    }
})

$ShowLogfileButton               = New-Object system.Windows.Forms.Button
$ShowLogfileButton.text          = "Show Logfile"
$ShowLogfileButton.width         = 170
$ShowLogfileButton.height        = 50
$ShowLogfileButton.enabled       = $false
$ShowLogfileButton.location      = New-Object System.Drawing.Point(215,610)
$ShowLogfileButton.Font          = 'Microsoft Sans Serif,10'
#endregion

$ACHVerificationTool.controls.AddRange(@($ProgressBar, $Title, $FilePanel, $ConsoleOutput, $ACHControlSettingsPanel, $VerifyButton, $ProgressLabel, $ShowLogfileButton, $ConsoleOutputSelectAllButton))
$FilePanel.controls.AddRange(@($ACHInputFilePathLabel,$ACHInputFilePath,$WorkingDirectoryLabel,$WorkingDirectory,$ACHInputFilePathButton,$WorkingDirectoryButton,$PatchFile,$LogBasic,$LogFull,$LogNone))
$ACHControlSettingsPanel.controls.AddRange(@($ImmediateOriginNameLabel, $ImmediateOriginName, $ODFILabel, $ODFI, $ImmediateOriginLabel, $ImmediateOrigin, $ImmediateDestinationNameLabel, $ImmediateDestinationName, $ImmediateDestinationLabel, $ImmediateDestination))

#region Error Validation Controls

# Add Validation Control
$ErrorProvider              = New-Object System.Windows.Forms.ErrorProvider
$ErrorProvider.BlinkStyle   = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink;
$ErrorProvider.Icon         = "$(Split-Path -Parent $PSCommandPath)\img\Papirus-Team-Papirus-Status-Dialog-warning.ico"
$SuccessProvider            = New-Object System.Windows.Forms.ErrorProvider
$SuccessProvider.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink;
$SuccessProvider.Icon       = "$(Split-Path -Parent $PSCommandPath)\img\Paomedia-Small-N-Flat-Sign-check.ico"

#endregion
$ACHVerificationTool.Add_FormClosing( {
    [xml]$ConfigFile = Get-SettingsFile
    $application_path = "$env:userprofile\AppData\Local\POSHTools\Verify-ACH\config"
    $config_path = $application_path + '\PreviousParameters.xml'

    # FILE SETTINGS
    $ConfigFile.Settings.Files.Input = '' # Set-NullString $ACHInputFilePath.Text
    $ConfigFile.Settings.Files.Output = Set-NullString $WorkingDirectory.Text
    $ConfigFile.Settings.Files.Patch = if ($PatchFile.Checked -eq $true) { '1' } else { '0' }
    $ConfigFile.Settings.Files.Logging = if ($LogFull.Checked -eq $true) { 'Full' } elseif ($LogBasic.Checked -eq $true) { 'Basic' } else { 'None' } # 'Full'

    # ACH CONTROL SETTINGS
    # Originator 
    $ConfigFile.Settings.ACH.Origin.Routing = Set-NullString $ImmediateOrigin.Text
    $ConfigFile.Settings.ACH.Origin.Name = Set-NullString $ImmediateOriginName.Text
    $ConfigFile.Settings.ACH.Origin.DFI = Set-NullString $ODFI.Text

    # Destination
    $ConfigFile.Settings.ACH.Destination.Routing = Set-NullString $ImmediateDestination.Text
    $ConfigFile.Settings.ACH.Destination.Name = Set-NullString $ImmediateDestinationName.Text

    # SAVE FILE
    $ConfigFile.Save($config_path) | Out-Null

})
$ACHVerificationTool.Add_Load({
    [xml]$ConfigFileLoad = Get-SettingsFile

    $ACHInputFilePath.Text           = $ConfigFileLoad.Settings.Files.Input
    $WorkingDirectory.Text           = $ConfigFileLoad.Settings.Files.Output
    $PatchFile.Checked               = if ($ConfigFileLoad.Settings.Files.Patch -eq '1') { $true } else { $false }
    if ($ConfigFileLoad.Settings.Files.Logging -eq 'Full') { 
        $LogFull.Checked = $true
    } elseif ($ConfigFileLoad.Settings.Files.Logging -eq 'Basic') {
        $LogBasic.Checked = $true
    } else {
        $LogNone.Checked = $true  
    }
    $ImmediateOrigin.Text            = $ConfigFileLoad.Settings.ACH.Origin.Routing
    $ImmediateOriginName.Text        = $ConfigFileLoad.Settings.ACH.Origin.Name
    $ODFI.Text                       = $ConfigFileLoad.Settings.ACH.Origin.DFI
    $ImmediateDestination.Text       = $ConfigFileLoad.Settings.ACH.Destination.Routing
    $ImmediateDestinationName.Text   = $ConfigFileLoad.Settings.ACH.Destination.Name
})
$ACHVerificationTool.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true })) | Out-Null