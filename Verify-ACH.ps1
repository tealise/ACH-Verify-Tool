# #############################################################################
# J. NASIATKA - FINSCRIPTS - ACH VERIFICATION TOOL
# NAME: Verify-ACH.ps1
#
# AUTHOR: Joshua Nasiatka
# DATE:   2018/09/07
# EMAIL:  dev@joshuanasiatka.com
#
# COMMENT:  This script can parse NACHA-formatted ACH files and check and correct
#           for errors.
#
# VERSION HISTORY
# 1.0 2019.02.25 Initial Version.
#
# #############################################################################

############################### CONFIG SETTINGS #################################
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ACHFileName,
    [Parameter(Mandatory = $false)]
    [hashtable]$FileHeader,
    [Parameter(Mandatory = $false)]
    [string]$OutputFolder,
    [Parameter(Mandatory = $false)]
    [switch]$Patch,
    [Parameter(Mandatory = $false)]
    [switch]$RunFromGUI
)

# LOAD DEPENDENCIES
. .\HelperFunctions.ps1
. .\ACHNacha.ps1
if ($PSBoundParameters.Count -ne 0) {
    $headless = $true
} else {
    $headless = $false
    . .\GUI.ps1
    exit
}

# For logging, expand window size
Expand-WindowSize -Width 640

if ($OutputFolder) {$output_path = $OutputFolder} else {
    $output_path = "Output"
}

if (($ACHFileName -eq '') -or ($ACHFileName -eq $null)) { 
    $ACHFileName = Get-FileName ("$($env:userprofile)\Desktop")
    if (-not $ACHFileName) { Add-Warning "You must provide a file"; exit; }
    $a = new-object -comobject wscript.shell 
    $intAnswer = $a.popup("Do you want to auto-patch the ach file?",0,"Patch ACH",4) 
    If ($intAnswer -eq 6) { 
        $Patch = $True
    } else { 
        $Patch = $False 
    } 
} else { Add-Log "Running in headless mode" }
if (-not (Test-Path $ACHFileName)) { Write-Warning "Unable to locate file"; exit}

if ($Patch) {
    $ach_file_object = Get-ChildItem $ACHFileName | Select *
    if ($OutputFolder) {
        $FixFileName = [string]$OutputFolder + '\' + [string]$ach_file_object.basename + '_Fixed.ach'
    } else {
        $FixFileName = [string]$ach_file_object.Directory + '\' + [string]$ach_file_object.basename + '_Fixed.ach'
    }
}

Start-Transcript "$output_path\ach_parse.log"

# INITIALIZE THE DEFAULT SETTINGS
$settings = @{}

<#
$settings = @{
    'immediate_destination'         = '011000015' # FED BOSTON
    'immediate_destination_name'    = 'FRB BOSTON'
    'immediate_origin'              = '021000018' # BANK OF NY MELLON
    'immediate_origin_name'         = 'BK OF NYC'
    'company_name'                  = 'BNY MELLON'
}
#>

# UPDATE SETTINGS HASHTABLE WITH PASSED $settings PARAMETER
if ($FileHeader) {
    $FileHeader.GetEnumerator() | %{
        $key = $_.Key
        $settings.$key = $FileHeader.$key
    }
}
$settings.originating_dfi_identification = $settings.immediate_origin.substring(0,8)

#################################################################################

$current_ach_value = "" # global, sorry
$current_ach_details = @()
$batch_resequence = $false
$entry_resequence = $true
$batch_sequence = 1 # '0000001'
$batch_temp_service_code = 0
$entry_sequence = [bigint]($settings.originating_dfi_identification + '0000001')
$entry_sequence_last = [bigint]($settings.originating_dfi_identification + '0000001')
$entry_sequence_bad = [bigint]($settings.originating_dfi_identification + '0000000')
$nine_record_counter = 0
$record_counter = 0

############################
# $ErrorActionPreference = "Stop"

Function ReadACHLine ($line) {
    # Get record type
    # 1 File Header Record
    # 5 Company/Batch Header Record
    # 6 Entry Detail Record (CCD/PPD Entries)
    # 7 Addenda Record
    # 8 Batch Control Record
    # 9 File Control Record
    $record_type = $line.substring(0,1).trim()
    if ($line -ne '9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999') { Add-LineBreak}
    Add-Log "Parsing line, detected record type $record_type"

    # 1 - FILE HEADER RECORD
    if ($record_type -eq '1') {
        $record_details = [PSCustomObject]@{
            'record_type'                      = $line.substring(0,1).trim()
            'priority_code'                    = $line.substring(1,2).trim()
            'immediate_destination'            = $line.substring(3,10).trim()
            'immediate_origin'                 = $line.substring(13,10).trim()
            'file_creation_date'               = $line.substring(23,6).trim()
            'file_creation_time'               = $line.substring(29,4).trim()
            'file_id_modifier'                 = $line.substring(33,1).trim()
            'record_size'                      = $line.substring(34,3).trim()
            'blocking_factor'                  = $line.substring(37,2).trim()
            'format_code'                      = $line.substring(39,1).trim()
            'immediate_destination_name'       = $line.substring(40,23).trim()
            'immediate_origin_name'            = $line.substring(63,23).trim()
            'reference_code'                   = $line.substring(86,8).trim()
        }
        
        # DISPLAY CURRENT RECORD VALUES
        $ach_append_line = Get-ACHLine $record_details
        Show-CurrentACHLine $record_details $line
        Set-ACHRecordDetailContents $record_details
        
        # WRITE OUT WARNINGS & FIXES
        if ($record_details.priority_code -ne '01') { 
            Add-Warning "1 - FILE CONTROL RECORD - Field 2 (Priority Code) - Must contain '01'"
            if ($Patch) { Add-Warning "Fixed!"; $record_details.priority_code = '01'}
        }
        
        if ($record_details.immediate_destination -ne $settings.immediate_destination) {
            Add-Warning "1 - FILE CONTROL RECORD - Field 3 (Immediate Destination) - Does Not Match '$($settings.immediate_destination)'"
            if ($Patch) { Add-Warning "Fixed!"; $record_details.immediate_destination = $settings.immediate_destination}
        }
        
        if ($record_details.immediate_origin -ne $settings.immediate_origin) {
            Add-Warning "1 - FILE CONTROL RECORD - Field 4 (Immediate Origin) - Does Not Match '$($settings.immediate_origin)'"
            if ($Patch) { Add-Warning "Fixed!"; $record_details.immediate_origin = $settings.immediate_origin}
        }
        
        if ($record_details.immediate_destination_name -ne $settings.immediate_destination_name) {
            Add-Warning "1 - FILE CONTROL RECORD - Field 11 (Immediate Destination Name) - Does Not Match '$($settings.immediate_destination_name)'"
            if ($Patch) { Add-Warning "Fixed!"; $record_details.immediate_destination_name = $settings.immediate_destination_name}
        }
        
        if ($record_details.immediate_origin_name -ne $settings.immediate_origin_name) {
            Add-Warning "1 - FILE CONTROL RECORD - Field 12 (Immediate Origin Name) - Does Not Match '$($settings.immediate_origin_name)'"
            if ($Patch) { Add-Warning "Fixed!"; $record_details.immediate_origin_name = $settings.immediate_origin_name}
        }
        
        # DISPLAY THE CORRECTED LINE
        if ($Patch) {
            $ach_append_line = Get-ACHLine $record_details
            Show-NewACHLine $record_details
        }
        
        
    # 5 - COMPANY/BATCH HEADER RECORD
    } elseif ($record_type -eq '5') {
        $record_details = [PSCustomObject]@{
            'record_type'                      = $line.substring(0,1).trim()
            'service_class_code'               = $line.substring(1,3).trim()
            'company_name'                     = $line.substring(4,16).trim()
            'company_discretionary_data_5'       = $line.substring(20,20).trim()
            'company_identification'           = $line.substring(40,10).trim()
            'standard_entry_class_code'        = $line.substring(50,3).trim()
            'company_entry_description'        = $line.substring(53,10).trim()
            'company_descriptive_date'         = $line.substring(63,6).trim()
            'effective_entry_date'             = $line.substring(69,6).trim()
            'settlement_date'                  = $line.substring(75,3).trim()
            'originator_status_code'           = $line.substring(78,1).trim()
            'originating_dfi_identification'   = $line.substring(79,8).trim()
            'batch_number'                     = $line.substring(87,7).trim()
        }
        
        # DISPLAY CURRENT RECORD VALUES
        Add-Log "Detected new batch: $($record_details.company_name) / $($record_details.company_discretionary_data_5) / $($record_details.standard_entry_class_code) / $($record_details.company_entry_description) "
        $ach_append_line = Get-ACHLine $record_details
        Show-CurrentACHLine $record_details $line
        Set-ACHRecordDetailContents $record_details
        $script:batch_temp_service_code = $record_details.service_class_code
        
        # WRITE OUT WARNINGS & FIXES
        # FIELD 2 - SERVICE CLASS CODE
        if ($record_details.service_class_code -eq '225') { 
            Add-Log "5 - BATCH HEADER RECORD - Field 2 (Service Class Code) - Debits Only (225) Specified"
        } elseif ($record_details.service_class_code -eq '220') { 
            Add-Log "5 - BATCH HEADER RECORD - Field 2 (Service Class Code) - Credits Only (220) Specified"
        } elseif ($record_details.service_class_code -eq '200') { 
            Add-Log "5 - BATCH HEADER RECORD - Field 2 (Service Class Code) - Mixed Debits/Credits (200) Specified"
        } else {
            Add-Warning "5 - BATCH HEADER RECORD - Field 2 (Service Class Code) - INVALID SERVICE CLASS CODE (200/220/225)"
        }
        
        # FIELD 12 - Originating DFI
        if ($record_details.originating_dfi_identification -ne $settings.originating_dfi_identification) {
            Add-Warning "5 - BATCH HEADER RECORD - Field 12 (Originating DFI) - Does Not Match '$($settings.originating_dfi_identification)'"
            if ($Patch) { Add-Warning "Fixed!"; $record_details.originating_dfi_identification = $settings.originating_dfi_identification}
        }
        
        # FIELD 13 - Batch Number
        if ($script:batch_resequence) {
            $record_details.batch_number = Format-Numeric $script:batch_sequence 7
        }
        if ([int]$record_details.batch_number -eq 0) {
            Add-Warning "5 - BATCH HEADER RECORD - Field 13 (Batch Number) - Cannot begin with 0"
            if ($Patch) { 
                Add-Warning "Fixed!"
                $record_details.batch_number = Format-Numeric $script:batch_sequence 7
                if (-not $script:batch_resequence) {
                    $script:batch_resequence = $True
                }
            }
        }
        
        # DISPLAY THE CORRECTED LINE
        if ($Patch) {
            $ach_append_line = Get-ACHLine $record_details
            Show-NewACHLine $record_details
        }

    # 6 - ENTRY DETAIL RECORD (CCD/PPD ENTRIES)
    } elseif ($record_type -eq '6') {
        $record_details  = [PSCustomObject]@{
            'record_type'                      = $line.substring(0,1).trim()
            'transaction_code'                 = $line.substring(1,2).trim()
            'receiving_dfi_identification'     = $line.substring(3,8).trim()
            'check_digit'                      = $line.substring(11,1).trim()
            'dfi_account_number'               = $line.substring(12,17).trim()
            'amount'                           = $(try{($line.substring(29,10).trim())/100}catch{$line.substring(29,10).trim()})
            'individual_identification_number' = $line.substring(39,15).trim()
            'individual_name'                  = $line.substring(54,22).trim()
            'company_discretionary_data_6'     = $line.substring(76,2).trim()
            'addenda_record_indicator'         = $line.substring(78,1).trim()
            'trace_number'                     = $line.substring(79,15).trim()
        }
        
        # DISPLAY CURRENT RECORD VALUES
        $ach_append_line = Get-ACHLine $record_details
        Show-CurrentACHLine $record_details $line
        Set-ACHRecordDetailContents $record_details
        
        # VERIFY TRACE NUMBER NOT 0 AND IF -PATCH, UPDATE SEQUENCE
        if ($script:entry_resequence) {
            $record_details.trace_number = $script:entry_sequence
            $script:entry_sequence += 1
        }
        if ([bigint]$record_details.trace_number -eq $entry_sequence_bad) {
            Add-Warning "6 - ENTRY DETAIL RECORD - Field 11 (Trace Number) - Cannot begin with 0"
            if ($Patch) { 
                Add-Warning "Fixed!"
                $record_details.trace_number = $script:entry_sequence #Format-Numeric $script:entry_sequence 15
                $script:entry_sequence += 1
            }
        }
        
        # DISPLAY THE CORRECTED LINE
        if ($Patch) {
            $ach_append_line = Get-ACHLine $record_details
            Show-NewACHLine $record_details
        }
        
    # 7 - ADDENDA RECORD
    } elseif ($record_type -eq '7') {
        $record_details = [PSCustomObject]@{
            'record_type'                      = $line.substring(0,1).trim()
            'addenda_type_code'                = $line.substring(1,2).trim()
            'addenda_related'                  = $line.substring(3,80).trim()
            'addenda_sequence_number'          = $line.substring(83,4).trim()
            'entry_detail_sequence_number'     = $line.substring(87,7).trim()
        }

    # 8 - BATCH CONTROL RECORD
    } elseif ($record_type -eq '8') {
        $record_details = [PSCustomObject]@{
            'record_type'                      = $line.substring(0,1).trim()
            'service_class_code'               = $line.substring(1,3).trim()
            'entry_addenda_count_8'              = $line.substring(4,6).trim()
            'entry_hash'                       = $line.substring(10,10).trim()
            'total_debit_entry'                = $(try{($line.substring(20,12).trim())/100}catch{$line.substring(20,12).trim()})
            'total_credit_entry'               = $(try{($line.substring(32,12).trim())/100}catch{$line.substring(32,12).trim()})
            'company_identification'           = $line.substring(44,10).trim()
            'message_authorization_code'       = $line.substring(54,19).trim()
            'reserved_8'                         = $line.substring(73,6).trim()
            'originating_dfi_identification'   = $line.substring(79,8).trim()
            'batch_number'                     = $line.substring(87,7).trim()
        }
        
        # DISPLAY CURRENT RECORD VALUES
        $ach_append_line = Get-ACHLine $record_details
        Show-CurrentACHLine $record_details $line
        Set-ACHRecordDetailContents $record_details
        
        # FIELD 2 - Service Class Code
        if ($record_details.service_class_code -ne $script:batch_temp_service_code) { 
            Add-Warning "8 - BATCH CONTROL RECORD - Field 2 (Service Class Code) - Must match batch header $($script:batch_temp_service_code)"
            if ($Patch) {
                Add-Warning "Fixed!"
                $record_details.service_class_code = $script:batch_temp_service_code
                $script:batch_temp_service_code = 0
            }
        }
        
        # FIELD 4 - Entry Hash
        if ($record_details.entry_hash -ne (Format-Numeric $script:batch_hash 10)) { 
            Add-Warning "8 - BATCH CONTROL RECORD - Field 4 (Entry Hash) - Incorrect Hash Calculation '$script:batch_hash'"
            if ($Patch) {
                Add-Warning "Fixed!"
                $record_details.entry_hash = $script:batch_hash
                $script:batch_hash = 0
            }
        }
        
        # FIELD 5 - Total Debit
        if ($record_details.total_debit_entry -ne $script:batch_total_debits) { 
            Add-Warning "8 - BATCH CONTROL RECORD - Field 5 (Total Debits) - Incorrect Debit Total '$script:batch_total_debits'"
            if ($Patch) {
                Add-Warning "Fixed!"
                $record_details.total_debit_entry = $script:batch_total_debits
                # $script:batch_total_debits = 0
            }
        }
        
        # FIELD 6 - Total Credit
        if ($record_details.total_credit_entry -ne $script:batch_total_credits) { 
            Add-Warning "8 - BATCH CONTROL RECORD - Field 6 (Total Credits) - Incorrect Credit Total '$script:batch_total_credits'"
            if ($Patch) {
                Add-Warning "Fixed!"
                $record_details.total_credit_entry = $script:batch_total_credits
                # $script:batch_total_credits = 0
            }
        }
        
        # FIELD 12 - Originating DFI
        if ($record_details.originating_dfi_identification -ne $settings.originating_dfi_identification) {
            Add-Warning "8 - BATCH CONTROL RECORD - Field 10 (Originating DFI) - Does Not Match '$($settings.originating_dfi_identification)'"
            if ($Patch) { Add-Warning "Fixed!"; $record_details.originating_dfi_identification = $settings.originating_dfi_identification}
        }
        
        # FIELD 13 - Batch Number
        if ($record_details.batch_number -ne (Format-Numeric $script:batch_count- 7)) { 
            Add-Warning "8 - BATCH CONTROL RECORD - Field 13 (Batch Count) - Must match batch header $($script:batch_count)"
            if ($Patch) {
                Add-Warning "Fixed!"
                $record_details.batch_number = Format-Numeric $script:batch_sequence 7
                $script:batch_sequence += 1
                # $script:batch_count = 0
            }
        } elseif ($script:batch_resequence) {
            $record_details.batch_number = Format-Numeric $script:batch_sequence 7
            $script:batch_sequence += 1
        }
        
        # DISPLAY THE CORRECTED LINE
        if ($Patch) {
            $ach_append_line = Get-ACHLine $record_details
            Show-NewACHLine $record_details
        }

    # 9 - FILE CONTROL RECORD
    } elseif ($record_type -eq '9') {
        if ($line -ne '9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999') {
            $record_details = [PSCustomObject]@{
                'record_type'                      = $line.substring(0,1).trim()
                'batch_count'                      = $line.substring(1,6).trim()
                'block_count'                      = $line.substring(7,6).trim()
                'entry_addenda_count_9'              = $line.substring(13,8).trim()
                'entry_hash'                       = $line.substring(21,10).trim()
                'total_debit_entry_in_file'        = $(try{($line.substring(31,12).trim())/100}catch{$line.substring(31,12).trim()})
                'total_credit_entry_in_file'       = $(try{($line.substring(43,12).trim())/100}catch{$line.substring(43,12).trim()})
                'reserved_9'                         = $line.substring(55,39).trim()
            }
            
            # DISPLAY CURRENT RECORD VALUES
            $ach_append_line = Get-ACHLine $record_details
            Show-CurrentACHLine $record_details $line
            Set-ACHRecordDetailContents $record_details
            
            # FIELD 2 - Batch Count
            if ($record_details.batch_count -ne (Format-Numeric $script:batch_count 6)) { 
                Add-Warning "9 - FILE CONTROL RECORD - Field 2 (Batch Count) - Incorrect batch count '$($script:batch_count)'"
                if ($Patch) {
                    Add-Warning "Fixed!"
                    $record_details.batch_count = $script:batch_count
                }
            }
            
            # FIELD 3 - Block Count
            $block_count_total = [Math]::Ceiling(($script:record_counter)/10)
            if ($record_details.block_count -ne (Format-Numeric $block_count_total 6)) {
                Add-Warning "9 - FILE CONTROL RECORD - Field 3 (Block Count) - Incorrect block count '$block_count_total'"
                if ($Patch) {
                    Add-Warning "Fixed!"
                    $record_details.block_count = (Format-Numeric $block_count_total 6)
                }
            }
            
            # FIELD 5 - Entry Hash
            if ($record_details.entry_hash -ne (Format-Numeric $script:file_hash 10)) { 
                Add-Warning "9 - FILE CONTROL RECORD - Field 5 (Entry Hash) - Incorrect Hash Calculation '$script:file_hash'"
                if ($Patch) {
                    Add-Warning "Fixed!"
                    $record_details.entry_hash = $script:file_hash
                }
            }
            
            # FIELD 6 - Total Debit
            if ($record_details.total_debit_entry_in_file -ne $script:file_total_debits) { 
                Add-Warning "9 - FILE CONTROL RECORD - Field 6 (Total Debits) - Incorrect Debit Total '$script:file_total_debits'"
                if ($Patch) {
                    Add-Warning "Fixed!"
                    $record_details.total_debit_entry_in_file = $script:file_total_debits
                }
            }
            
            # FIELD 7 - Total Credit
            if ($record_details.total_credit_entry_in_file -ne $script:file_total_credits) { 
                Add-Warning "9 - FILE CONTROL RECORD - Field 7 (Total Credits) - Incorrect Credit Total '$script:file_total_credits'"
                if ($Patch) {
                    Add-Warning "Fixed!"
                    $record_details.total_credit_entry_in_file = $script:file_total_credits
                }
            }
            
            # DISPLAY THE CORRECTED LINE
            if ($Patch) {
                $ach_append_line = Get-ACHLine $record_details
                Show-NewACHLine $record_details
            }
            
        } else {
            Add-Log "Detected end of file filler."
            # $filler_line = '9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999'
            # Write-Output ('-'*94)  $filler_line  ('-'*94)
            $script:nine_record_counter += 1
        }

    # NO OTHER RECORD TYPES
    } else {
        Write-Warning "Invalid record, skipping..."
        return
    }
    
    Set-ACHRecordContents $ach_append_line
}


# INITIALIZE COUNTS AND HASHES
[int]$batch_hash = 0
[int]$file_hash = 0
$batch_total_debits = 0
$batch_total_credits = 0
$batch_count = 0
$transaction_count = 0
$file_total_debits = 0
$file_total_credits = 0

Function Invoke-VerifyBatch {
    param([hashtable]$settings)

    $ach_data = Get-Content -Path $ACHFileName
    $total_record_count = $ach_data.Count
    # $ach_filtered = @()
    # $csv_data = @()
    $NewACHContents = @()

    Write-Output "File/Batch Control Info:"
    $settings | Format-Table -AutoSize

    foreach ($line in $ach_data) {
        # Update GUI progress bar if using GUI
        if ($RunFromGUI) { $ProgressBar.Value = [int](($record_counter/$total_record_count)*100)}
        ReadACHLine $line
        $NewACHContents += $script:current_ach_value # | Format-Table -Property * -AutoSize
        $script:current_ach_value = $null # MUST CLEAR GLOBAL
        $line_details = $script:current_ach_details
        $script:current_ach_details = @() # MUST CLEAR GLOBAL
        
        if ($line[0] -eq '5') {
            $script:batch_total_debits = 0
            $script:batch_total_credits = 0
            $script:batch_hash = 0
        } elseif ($line[0] -eq '6') {
            $script:batch_hash += [int]$line_details.receiving_dfi_identification
            $script:transaction_count += 1
            $six_record_type = $line.substring(1,2).trim()
            if ($six_record_type -eq '27' -or $six_record_type -eq '37') {
                $script:batch_total_debits += $line_details.amount
            } else {
                $script:batch_total_credits += $line_details.amount
            }
        } elseif ($line[0] -eq '8') {
            Write-Output "`r`nBatch Total Debits: $($script:batch_total_debits.ToString("$##0.00"))"
            Write-Output "Batch Total Credits: $($script:batch_total_credits.ToString("$##0.00"))"
            Write-Output "Entry Hash Code: $($script:batch_hash.ToString("0000000000"))"
            $script:file_total_debits += $script:batch_total_debits
            $script:file_total_credits += $script:batch_total_credits
            $script:file_hash += $script:batch_hash
            $script:batch_count += 1
        } elseif ($line[0] -eq '9' -and $line -ne '9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999') {
            Write-Output "`r`nFile Total Debits: $($script:file_total_debits.ToString("$##0.00"))"
            Write-Output "File Total Credits: $($script:file_total_credits.ToString("$##0.00"))"
            Write-Output "Total Batches: $script:batch_count"
            Write-Output "Total Entry/Addendas: $script:transaction_count"
            Write-Output "Entry Hash Code: $($script:file_hash.ToString("0000000000"))"
            Write-Output "`r`n----END OF PROCESSING DETAILS----`r`n"
        }
        
        $script:record_counter += 1

    }
    
    if (3 -ne $script:batch_count) {
        Add-LineBreak
        Add-Warning "Incorrect number of filler lines (9), must match batch count"
    }
    
    # END OF FILE FILLER 9 ROWS MUST MATCH BATCH COUNT
    # think of it as a closing parentheses and the 5 record is the beginning paraenthese
    if ($Patch) {
        $temp_index = 0
        while ($temp_index -ne $script:batch_count) {
            $NewACHContents += '9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999'
            $temp_index += 1
        }
    }
    
    Add-LineBreak
    
    if ($Patch) {
        Add-Log "Outputting fixed ACH file at the following path: `r`n$FixFileName"
        Add-Log "Displaying final ACH Output"
        $NewACHContents
        $NewACHContents | Out-File -FilePath $FixFileName -encoding ascii
    }

}

Write-Output @"
+---------------------------+
| ACH Parse & Patch Tool    |
| v2.0                      |
| by Josh Nasiatka          |
+---------------------------+`r`n
"@

Invoke-VerifyBatch $settings

Stop-Transcript
