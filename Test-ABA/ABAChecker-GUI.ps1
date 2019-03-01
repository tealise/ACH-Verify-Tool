[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$current_path = Split-Path -Parent $PSCommandPath
if ($current_path -eq '') { $current_path = '.' }

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "ABA Checker"
$objForm.Size = New-Object System.Drawing.Size(300, 200) 
$objForm.StartPosition = "CenterScreen"
$objForm.KeyPreview = $True
$objForm.Add_KeyDown( {if ($_.KeyCode -eq "Enter") 
        {$x = $objTextBox.Text; $objForm.Close()}})
$objForm.Add_KeyDown( {if ($_.KeyCode -eq "Escape") 
        {$objForm.Close()}})

# Add Ok Button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75, 120)
$OKButton.Size = New-Object System.Drawing.Size(75, 23)
$OKButton.Text = "OK"
$OKButton.Add_Click( {
        $objForm.DialogResult = [System.Windows.Forms.DialogResult]::OK;
    })
$objForm.Controls.Add($OKButton)

# Add Cancel Button
$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150, 120)
$CancelButton.Size = New-Object System.Drawing.Size(75, 23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)


# Add Textbox Label
$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10, 20) 
$objLabel.Size = New-Object System.Drawing.Size(280, 20) 
$objLabel.Text = "ABA Routing Number:"
$objForm.Controls.Add($objLabel) 
# Add Textbox
$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Location = New-Object System.Drawing.Size(10, 40) 
$objTextBox.Size = New-Object System.Drawing.Size(200, 20)
$objTextBox.Add_TextChanged({
    If ($objTextBox.Text -match "\d{8}") {
        $result = Test-ABA -RoutingNumber $objTextBox.Text
        if ($result.code -ne 200) {
            # Invalid
            $ErrorProvider.SetError($objTextbox, "$($result.code): $($result.message)");
            $SuccessProvider.SetError($objTextBox, "")
        } else {
            # Valid
            $SuccessProvider.SetError($objTextBox, $($result.customer_name))
            $ErrorProvider.SetError($objTextBox, "")
            $objTextBox2.Text = $result.customer_name
            Write-Host $result
        }
    }
    Else {
        # Invalid
        $ErrorProvider.SetError($objTextbox, "Please use 8 Digit ABA routing number");
        $SuccessProvider.SetError($objTextBox, "")
    }

})
$objForm.Controls.Add($objTextBox)


# Add Textbox Label
$objLabel2 = New-Object System.Windows.Forms.Label
$objLabel2.Location = New-Object System.Drawing.Size(10, 70) 
$objLabel2.Size = New-Object System.Drawing.Size(280, 20) 
$objLabel2.Text = "Institution Name:"
$objForm.Controls.Add($objLabel2) 
# Add Textbox
$objTextBox2 = New-Object System.Windows.Forms.TextBox 
$objTextBox2.Location = New-Object System.Drawing.Size(10, 90) 
$objTextBox2.Size = New-Object System.Drawing.Size(200, 20)
$objForm.Controls.Add($objTextBox2) 

# Add Validation Control
$ErrorProvider = New-Object System.Windows.Forms.ErrorProvider
$ErrorProvider.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink;
$ErrorProvider.Icon = "$($current_path)\..\img\Papirus-Team-Papirus-Status-Dialog-warning.ico"
$SuccessProvider = New-Object System.Windows.Forms.ErrorProvider
$SuccessProvider.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink;
$SuccessProvider.Icon = "$($current_path)\..\img\Paomedia-Small-N-Flat-Sign-check.ico"
$objForm.Topmost = $True
$objForm.Add_Shown( {$objForm.Activate()})
$objForm.ShowDialog()